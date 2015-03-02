define drush (
  $bin = $title,
  $revision = '6.x',
  $default = false,
  $user = 'root',
  $group = 'root',
  $src_path = "/usr/local/src",
  $bin_path = "/usr/local/bin",
) {

  if ! defined(Package['git']) {
    package { 'git': }
  }
  if ! defined(::Php::Composer['/usr/local/bin']) {
    ::php::composer { '/usr/local/bin':
      bin => 'composer',
    }
  }

  vcsrepo { "${src_path}/${bin}":
    ensure => $ensure,
    provider => git,
    source => 'https://github.com/drush-ops/drush.git',
    revision => $revision,
    require => Package['git'],
    user => $user,
    owner => $user,
    group => $group,
    notify => Exec["${bin} initial run"],
  } ~>
  exec { "${bin} composer install":
    command => "composer install > composer.log",
    environment => 'COMPOSER_HOME=/root',
    cwd => "${src_path}/${bin}",
    onlyif => "test -f ${src_path}/${bin}/composer.json",
    refreshonly => true,
    user => $user,
    require => ::Php::Composer['/usr/local/bin'],
    notify => Exec["${bin} initial run"],
    timeout => 600,
  }

  exec { "${bin} initial run":
    command => "${src_path}/${bin}/drush cache-clear drush",
    user => $user,
    refreshonly => true,
  }

  file { "${bin_path}/${bin}":
    ensure  => link,
    target  => "${src_path}/${bin}/drush",
    require => Vcsrepo["${src_path}/${bin}"],
  }

  if $default {
    file { "${bin_path}/drush":
      ensure  => link,
      target  => "${src_path}/${bin}/drush",
      require => Vcsrepo["${src_path}/${bin}"],
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

  $src_path = getparam(::Drush[$bin], 'src_path')
  $bin_path = getparam(::Drush[$bin], 'bin_path')
  $user = getparam(::Drush[$bin], 'user')

  $destination = "${src_path}/${bin}/commands"

  exec { "${bin} dl ${module}":
    command => "${bin} -y dl ${module} --destination=${destination}",
    user => $user,
    creates => "${destination}/${module}",
    notify => Exec["${bin} initial run"],
    require => File["${bin_path}/${bin}"],
  }

}
