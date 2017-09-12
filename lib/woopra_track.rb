require 'woopra_track/version'
require 'woopra_track/helper'

module WoopraTrack
  autoload :Tracker, 'woopra_track/tracker'

  class << self
    def included(model_class)
      model_class.extend self
    end
  end

  def woopra(request, config=nil, cookies=nil)
    @woopra = Tracker.new request

    @woopra.config(config)      unless config.nil?
    @woopra.set_cookie(cookies) unless cookies.nil?
  end
end

if defined? ActionView::Base
  ActionView::Base.send :include, WoopraTrack::Helper
end
