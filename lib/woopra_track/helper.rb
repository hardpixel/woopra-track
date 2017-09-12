module WoopraTrack
  module Helper
    def woopra_javascript_tag
      @woopra.try :javascript_tag
    end
  end
end
