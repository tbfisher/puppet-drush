# Gets drush aliases defined on a remote system and writes them locally.

define drush::remote_aliases (
  $host = $name,
  $namespace = $name,
  $user = 'root'
){

  case $user {
    root: { $home = '/root' }
    default: { $home = "/home/${user}" }
  }

  # ssh2
  if (! defined(Package['libssh2-php'])) {
    package { 'libssh2-php': }
  }
  if (! defined(Pear::Package['ssh2'])) {
    pear::package { "ssh2":
      repository => "pecl.php.net",
    }
  }

  if (! defined(File['::drush::remote_aliases script'])) {
    file { '::drush::remote_aliases script':
      path => "${home}/.drush/get_drush_aliases.php",
      ensure => file,
      source => "puppet:///modules/drush/get_drush_aliases.php",
    }
  }
  exec { "php ${home}/.drush/get_drush_aliases.php ${host} > ${home}/.drush/${namespace}.aliases.drushrc.php":
    creates => "${home}/.drush/${namespace}.aliases.drushrc.php",
    user => $user,
    require => File['::drush::remote_aliases script'],
  }

}