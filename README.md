# Puppet Module: Drush

## Requirements

-   [tbfisher/puppet-php](https://github.com/tbfisher/puppet-php)

## Usage

Install drush 5, 6, and 7. Link `drush` to 6.

    drush { 'drush5': revision => '5.x' }
    drush { 'drush6': revision => '6.x', default => true }
    drush { 'drush7': revision => 'master' }
