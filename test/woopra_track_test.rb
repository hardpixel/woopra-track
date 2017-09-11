require 'test_helper'

class WoopraTrackTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::WoopraTrack::VERSION
  end
end
