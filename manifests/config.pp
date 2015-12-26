# == Define: aem::config
#
# Configure the AEM instance with the appropriate parameter values
#
# Do not use this defines directly.
#
define aem::config(
  $context_root,
  $debug_port,
  $group,
  $home,
  $jvm_mem_opts,
  $jvm_opts,
  $osgi_configs,
  $port,
  $runmodes,
  $sample_content,
  $type,
  $user
) {

  File {
    group => $group,
    owner => $user,
  }


  # Create the env script
  file { "${home}/crx-quickstart/bin/start-env":
    ensure  => file,
    content => template("${module_name}/start-env.erb"),
    mode    => '0775',
  }

  # Rename the original start script.
  file { "${home}/crx-quickstart/bin/start.orig":
    ensure  => file,
    replace => false,
    source  => "${home}/crx-quickstart/bin/start",
    mode    => '0775',
  }

  # Create the start script
  file { "${home}/crx-quickstart/bin/start":
    ensure  => file,
    content => template("${module_name}/start.erb"),
    mode    => '0775',
    require => File["${home}/crx-quickstart/bin/start.orig"],
  }

  # Create the install folder in case there are any OSGi configurations; now or in the future
  file {"${home}/crx-quickstart/install" :
    ensure => directory,
    mode   => '0775',
  }

  if $osgi_configs {

    if is_array($osgi_configs) {
      $_osgi_configs = $osgi_configs
    } else {
      $_osgi_configs = [$osgi_configs]
    }

    $_osgi_configs.each | Hash $cfg | {
      $osgi_file_name = $cfg.keys[0]
      $properties = $cfg[$osgi_file_name]
      aem::osgi::config::file { $osgi_file_name :
        group      => $group,
        home       => $home,
        properties => $properties,
        user       => $user
      }
      
    }
  }
}
