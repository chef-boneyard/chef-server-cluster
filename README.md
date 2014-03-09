# oc-ec

## Requirements

### Platform:

64 bit Ubuntu 12.04

## Attributes

## Recipes

default - The only recipe needed, sets up EC

## Testing

The cookbook provides the following Rake tasks for testing:

    rake foodcritic                   # Lint Chef cookbooks
    rake integration                  # Alias for kitchen:all
    rake kitchen:all                  # Run all test instances
    rake kitchen:default-ubuntu-1204  # Run default-ubuntu-1204 test instance
    rake rubocop                      # Run RuboCop style and lint checks
    rake spec                         # Run ChefSpec examples
    rake test                         # Run all tests

## License and Author

- Author: Chef
- Copyright (C) 2014 Chef Software

All rights reserved.
