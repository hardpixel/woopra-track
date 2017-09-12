require 'woopra_track/version'
require 'woopra_track/tracker'

module WoopraTrack
  def config(request, config=nil, cookies=nil)
    tracker = Tracker.new request

    tracker.config(config)      unless config.nil?
    tracker.set_cookie(cookies) unless cookies.nil?

    tracker
  end
end
