# base class
class drush (
  $user     = 'root',
  $group    = 'root',
  $home     = '/root',
  $src_path = "/usr/local/src",
  $bin_path = "/usr/local/bin",
) {}

# a drush installation
define drush::bin (
  $revision,
  $default = false,
) {

  include drush

  $src_path = "${::drush::src_path}/${title}"

  vcsrepo { $src_path:
    ensure   => $ensure,
    provider => git,
    source   => 'https://github.com/drush-ops/drush.git',
    revision => $revision,
    require  => Package['git'],
    user     => $::drush::user,
    owner    => $::drush::user,
    group    => $::drush::group,
    notify   => Exec["drush::bin ${title} initial run"],
  }

  exec { "drush::bin ${title} install composer":
    command     => 'curl -sS https://getcomposer.org/installer | php',
    cwd         => "${src_path}",
    user        => $::drush::user,
    onlyif      => "test -f ${src_path}/composer.json",
    refreshonly => true,
    subscribe   => Vcsrepo[$src_path],
    notify      => Exec["drush::bin ${title} initial run"],
  } ~>
  exec { "drush::bin ${title} composer install":
    command     => "${src_path}/composer.phar install",
    environment => "COMPOSER_HOME=${::drush::home}",
    cwd         => "${src_path}",
    onlyif      => "test -f ${src_path}/composer.json",
    refreshonly => true,
    user        => $user,
    timeout     => 600,
    subscribe   => Vcsrepo[$src_path],
    notify      => Exec["drush::bin ${title} initial run"],
  }

  exec { "drush::bin ${title} initial run":
    command     => "${src_path}/drush cache-clear drush",
    user        => $user,
    refreshonly => true,
  }

  file { "${::drush::bin_path}/${title}":
    ensure  => link,
    target  => "${src_path}/drush",
    require => Vcsrepo["${src_path}"],
  }

  if $default {
    file { "${::drush::bin_path}/drush":
      ensure  => link,
      target  => "${src_path}/drush",
      require => Vcsrepo[$src_path],
    }
  }
}

define drush::module (
  $module,
  $bin,
  $version = false,
) {

  $src_path = "${::drush::src_path}/${bin}"

  $destination = "${src_path}/commands"

  if $version {
    $cmd = "${bin} -y dl ${module}-${version} --destination=${destination}"
  }
  else {
    $cmd = "${bin} -y dl ${module} --destination=${destination}"
  }

  exec { "${bin} dl ${module}":
    command => $cmd,
    user => $::drush::user,
    creates => "${destination}/${module}",
    require => Exec["drush::bin ${bin} initial run"],
  }

}
