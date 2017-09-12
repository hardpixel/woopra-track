require 'uri'
require 'typhoeus'
require 'logger'

module WoopraTrack
  class Tracker
    @@application_id = 'rails'
    @@default_config = {
      domain:            nil,
      cookie_name:       'wooTracker',
      cookie_domain:     nil,
      cookie_path:       '/',
      ping:              true,
      ping_interval:     12000,
      idle_timeout:      300000,
      download_tracking: true,
      outgoing_tracking: true,
      download_pause:    200,
      outgoing_pause:    400,
      ignore_query_url:  true,
      hide_campaign:     false,
      ip_address:        nil,
      cookie_value:      nil,
    }

    def initialize(request)
      @request         = request
      @current_config  = @@default_config
      @custom_config   = { app: @@application_id }
      @user            = {}
      @events          = []
      @user_up_to_date = true
      @has_pushed      = false

      @current_config[:domain]        = @request.host
      @current_config[:cookie_domain] = @request.host
      @current_config[:ip_address]    = get_client_ip
      @current_config[:cookie_value]  = @request.cookies[@current_config[:cookie_name]] || random_cookie
    end

    def config(data)
      data = Hash(data).select { |k, _v| k.in? @@default_config.keys }
      data = data.except(:ip_address, :cookie_value)

      @custom_config.merge!(data)
    end

    def identify(user)
      @user            = user
      @user_up_to_date = false
    end

    def track(*args)
      event_name = nil
      event_data = nil
      back_end   = false

      args.each do |param|
        case param
        when String
          event_name = param
        when Hash
          event_data = param
        when TrueClass
          back_end = param
        end
      end

      if back_end
        http_request([event_name, event_data])
      else
        @events << [event_name, event_data]
      end
    end

    def push(back_end=false)
      if not @user_up_to_date
        if back_end
          http_request()
        else
          @has_pushed = true
        end
      end
    end

    def javascript_tag
      code = ['(function(){var t,i,e,n=window,o=document,a=arguments,s="script",r=["config","track","identify","visit","push","call"],c=function(){var t,i=this;for(i._e=[],t=0;r.length>t;t++)(function(t){i[t]=function(){return i._e.push([t].concat(Array.prototype.slice.call(arguments,0))),i}})(r[t])};for(n._w=n._w||{},t=0;a.length>t;t++)n._w[a[t]]=n[a[t]]=n[a[t]]||new c;i=o.createElement(s),i.async=1,i.src="//static.woopra.com/js/w.js",e=o.getElementsByTagName(s)[0],e.parentNode.insertBefore(i,e)})("woopra");']

      code << "woopra.config(#{@custom_config.to_json});" if @custom_config.length != 0
      code << "woopra.identify(#{@user.to_json});" if not @user_up_to_date

      @events.each do |event|
        if event.first.nil?
          code << "woopra.track();"
        else
          code << "woopra.track('#{event.first}', #{event.second.to_json});"
        end
      end

      code << "woopra.push();" if @has_pushed

      "<script>\n#{code.join("\n")}\n</script>".html_safe
    end

    def set_cookie(cookies)
      cookies[@current_config[:cookie_name]] = @current_config[:cookie_value]
    end

    private

      def http_request(event=nil)
        logger      = Logger.new(STDOUT)
        request_url = 'https://www.woopra.com'
        get_params  = {
          host:    @current_config[:domain],
          cookie:  @current_config[:cookie_value],
          ip:      @current_config[:ip_address],
          timeout: @current_config[:idle_timeout]
        }

        user_params = Hash[@user.map { |k, v| [:"cv_#{k}", "#{v}"] }]
        get_params  = get_params.merge(user_params)

        if event.nil?
          request_url = URI.join(request_url, 'track/ce')
        else
          request_url = URI.join(request_url, 'track/identify')

          if event.first.nil?
            get_params = get_params.merge(event: 'pv', ce_url: @request.url)
          else
            event_data = Hash[Array(event.second).map { |k, v| [:"ce_#{k}", "#{v}"] }]
            get_params = get_params.merge(event: event.first).merge(event_data)
          end
        end

        request_url.query = URI.encode_www_form(get_params.merge(ce_app: @@application_id))
        request_headers   = { 'User-Agent' => @request.env['HTTP_USER_AGENT'] }
        request_response  = Typhoeus.get(request_url, headers: request_headers)

        if request_response.success?
          logger.info("Woopra") { "Success: #{request_url}" }
        elsif request_response.timed_out?
          logger.warn("Woopra") { "Timeout: #{request_url}" }
        elsif request_response.code == 0
          logger.error("Woopra") { "#{request_response.return_message}, #{request_url}" }
        else
          logger.error("Woopra") { "WOOPRA Failed: #{request_response.code.to_s}, #{request_url}" }
        end
      end

      def random_cookie
        o = [('0'..'9'), ('A'..'Z')].map { |i| i.to_a }.flatten
        (0..12).map { o[rand(o.length)] }.join
      end

      def get_client_ip
        if not @request.env['HTTP_X_FORWARDED_FOR'].nil?
          @request.env['HTTP_X_FORWARDED_FOR'].split(',').first.strip
        else
          @request.remote_ip
        end
      end
  end
end
