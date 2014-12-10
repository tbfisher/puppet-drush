<?php

/**
 * @file
 * Gets drush aliases PHP from a remote host, and appends host and user data to
 * each alias.
 */

// A simple command line UI.
if ($argc != 2) {
  die("Usage: php get_drush_aliases.php user@host\n");
}
$host = $argv[1];
list($user, $hostname) = explode('@', $host);

// Connect to remote server.
$connection = ssh2_connect($hostname, 22);
if (!ssh2_auth_agent($connection, $user)) {
  die("SSH authentication failed.\n");
}

/**
 * Runs a remote command and returns the output.
 */
function remote_exec($connection, $command) {
  if (!$stream = ssh2_exec($connection, $command)) {
    die("Could not execute remote command {$command}.");
  }
  stream_set_blocking($stream, TRUE);
  $out = '';
  while ($s = fgets($stream)) {
    $out .= $s;
  }
  fclose($stream);
  return $out;
}

/**
 * Runs a remote drush command.
 */
function remote_drush($connection, $command) {
  // WTF.
  return remote_exec($connection, "bash -l `which drush` {$command}");
}

// Get a list of alias definition files on the remote.
$alias_files = json_decode(remote_drush($connection,
  'status --format=json --full drush-alias-files'));
$alias_files = $alias_files->{'drush-alias-files'};

/**
 * Evaluate all alias files and return a merged $aliases array.
 */
function read_aliases($connection, $paths) {
  foreach ($paths as $path) {
    if ($php = remote_exec($connection, "cat {$path}")) {
      // Reads into local scope.
      eval(substr($php, strpos($php, '<?php') + 5));
    }
  }
  // All we care about are items added to $aliases array.
  return $aliases;
}
$aliases = read_aliases($connection, $alias_files);

// Add remote info to each alias.
foreach ($aliases as &$alias) {
  $alias['remote-host'] = $hostname;
  $alias['remote-user'] = $user;
}

// Write out aliases as drush expects, in PHP,
print "<?php\n";
foreach ($aliases as $key => $val) {
  // And in the form: $aliases['key'] = array(...);
  print '$aliases["' . $key . '"] = ' . var_export($val, TRUE) . ";\n";
}
