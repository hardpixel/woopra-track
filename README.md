# WoopraTrack

Tracking library for [woopra.com](https://www.woopra.com). Woopra analytics client-side and server-side tracking helper.

[![Gem Version](https://badge.fury.io/rb/woopra_track.svg)](https://badge.fury.io/rb/woopra_track)
[![Build Status](https://travis-ci.org/hardpixel/woopra-track.svg?branch=master)](https://travis-ci.org/hardpixel/woopra-track)
[![Code Climate](https://codeclimate.com/github/hardpixel/woopra-track/badges/gpa.png)](https://codeclimate.com/github/hardpixel/woopra-track)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'woopra_track'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install woopra_track

## Usage

To enable tracker in a ActionController controller, include the `WoopraTrack` concern in your class:

```ruby
class PagesController < ApplicationController
  include WoopraTrack
end
```

You can then configure the tracker in your controller. For example, if you want to set up tracking with Woopra on your homepage, the controller should look like and then you will have the `@woopra` instance variable available:

```ruby
class PagesController < ApplicationController
  def home
    config = { domain: 'website.com' }
    woopra(request, config)

    # Your code here...
  end
end
```

You can also customize all the properties of the woopra during that step by adding them to the `config_hash`. For example, to also update your idle timeout (default: 30 seconds):

```ruby
# Using woopra function
config = { domain: 'website.com', idle_timeout: 15000 }
woopra(request, config)

# Using @woopra instance variable
@woopra.config({ idle_timeout: 15000 })
```

To add custom visitor properties, you should use the `identify` function:

```ruby
@woopra.identify({
  email:   'johndoe@website.com',
  name:    'John Doe',
  company: 'Business'
})
```

If you wish to identify a user without any tracking event, don't forget to `push` the update to woopra:

```ruby
# Push through front-end
@woopra.identify(user_hash)
@woopra.push

# Push through back-end
@woopra.identify(user_hash)
@woopra.push(true)
```

If you wish to track page views, just call `track`:

``` ruby
# Front-end tracking:
@woopra.track

# Back-end tracking:
@woopra.track(true)
```

You can also track custom events through the front-end or the back-end. With all the previous steps done at once, your controller should look like:

``` ruby
class PagesController < ApplicationController
  include WoopraTrack

  def home
    # Initialize and configure woopra tracker
    config = { domain: 'website.com', idle_timeout: 15000 }
    woopra(request, config)

    # Identify user
    @woopra.identify({
      email:   'johndoe@website.com',
      name:    'John Doe',
      company: 'Business'
    })

    # Track a custom event through the front end...
    @woopra.track('play', {
      artist: 'Dave Brubeck',
      song:   'Take Five',
      genre:  'Jazz'
    })

    # ... and through the back end by passing the optional argument `true`
    @woopra.track('signup', {
      company:  'Business',
      username: 'johndoe',
      plan:     'Gold'
    }, true)

    # Enable front-end tracking
    @woopra.track

    # Your code here...
  end
end
```

and add the code in your template's header (here `home.html.erb`)

```erb
<!DOCTYPE html>
<html>
  <head>
    <!-- Your header here... -->
    <%= woopra_javascript_tag %>
  </head>
   <body>
    <!-- Your body here... -->
  </body>
</html>
```

If you wish to track your users only through the back-end, you should set the cookie on your user's browser. However, if you are planning to also use front-end tracking, don't even bother with that step, the JavaScript tracker will handle it for you.

``` ruby
# During initialization
config = { domain: 'website.com', idle_timeout: 15000 }
woopra(request, config, cookies)

# Using set cookie function
@woopra.set_cookie(cookies)
```

If you want to enable logging for back-end tracking requests, just call `enable_logging`:

``` ruby
@woopra.enable_logging
```

You can also disable tracking globally, by setting `disable_tracking` to `true` in the config hash.

``` ruby
config = { domain: 'website.com', idle_timeout: 15000, disable_tracking: true }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hardpixel/woopra-track.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
