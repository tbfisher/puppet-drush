define drush (
  $bin = $title,
  $revision = '6.x',
  $default = false,
) {

  $lib_path = "/usr/share/${bin}"
  $bin_path = "/usr/bin/${bin}"

  if ! defined(Package['git']) {
    package { 'git': }
  }
  if ! defined(::Php::Composer['/usr/local/bin']) {
    ::php::composer { '/usr/local/bin':
      bin => 'composer',
    }
  }

  vcsrepo { $lib_path:
    ensure => $ensure,
    provider => git,
    source => 'https://github.com/drush-ops/drush.git',
    revision => $revision,
    require => Package['git'],
  }

  file { $bin_path:
    ensure  => link,
    target  => "${lib_path}/drush",
  }

  exec { "${bin} composer install":
    command => "composer install > composer.log",
    environment => 'COMPOSER_HOME=/root',
    cwd => $lib_path,
    onlyif => "test -f ${lib_path}/composer.json",
    creates => "${lib_path}/vendor/autoload.php",
    require => [
      Vcsrepo[$lib_path],
      ::Php::Composer['/usr/local/bin'],
    ],
    timeout => 600,
  }

  exec { "${bin} initial run":
    command => "${bin} cache-clear drush",
    subscribe => [
      File[$bin_path],
      Exec["${bin} composer install"],
    ],
    refreshonly => true,
  }

  if $default {
    file { '/usr/bin/drush':
      ensure  => link,
      target  => "${lib_path}/drush",
      require => Exec["${bin} initial run"],
    }
  }
}

define drush::module (
  $module,
  $bin,
) {

  if ! defined(::Drush[$bin]) {
    fail("missing ::drush{'${bin}'}")
  }

  $destination = "/usr/share/${bin}/commands"

  exec { "${bin} dl ${module}":
    command => "drush -y dl ${module} --destination=${destination}",
    creates => "${destination}/${module}",
    require => File["/usr/bin/${bin}"],
  }

}
