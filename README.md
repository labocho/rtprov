# rtprov

Yamaha router (RTX or NVR series etc.) provisioning tool.

## Installation

    $ gem install rtprov

## Requirements

rtprov requires following commands. Please install these.

* colordiff (or diff)
* lftp
* ssh
* which

## Preparation

* Enable SSH and SFTP access.
* Create user and allow SSH access and administration.

And you must know following passwords.

* User password
* Administrator password
* Anonymous user password

## Usage

### rtprov new

`rtprov new` creates directory and some files.
Please run other commands in created directory.

It creates `./encryption_key` to encrypt router configurations.
.gitignore ignores this. Please store it securely.

    $ rtprov new my_office


### rtprov edit

`rtprov edit` creates or edits router configuration file in `./routers` directory. It is encrypted by `./encryption_key` file.
rtprov launches `ENV["RTPROV_EDITOR"]` or `ENV["EDITOR"]` to edit file.

    # Launch editor and create/update routers/my_router.yml.enc
    $ rtprov edit my_router


### rtprov show

`rtprov show` print router configuration to stdout.

    # Prints decrypted routers/my_router.yml.enc
    $ rtprov show my_router

### rtprov get

`rtprov get` gets config file from router and print to stdout.
If `-n, --number` option is not specified, it gets `config0`.

    # Get config0 from my_router and print to stdout
    $ rtprov get my_router
    # Get config1 from my_router and print to stdout
    $ rtprov get --number 1 my_router


### rtprov put

`rtprov put` puts config file to router and load it.
Second argument is template name. If you create `templates/my_config.erb`, template name is `my_config`.
If `-n, --number` option is not specified, it gets `config0`.

It prints diff before transfer and ask you.
rtprov uses `ENV["RTPROV_DIFF"]` or `colordiff` or `diff` to print diff.

    # Rendering templates/my_config.erb and put to my_route as config0 and load it.
    $ rtprov put my_router my_config
    # Rendering templates/my_config.erb and put to my_route as config1 and load it.
    $ rtprov put my_router --number 1 my_config


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/labocho/rtprov.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
