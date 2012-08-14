# Class: puppet::master
#
# This class installs and configures a Puppet master
#
# Parameters:
#
# Requires:
#
#  Class['inifile']
#  Class['stdlib']
#
# Sample Usage:
#
#  $modulepath = [
#    "/etc/puppet/modules/site",
#    "/etc/puppet/modules/dist",
#  ]
#
#  class { "puppet::master":
#    modulepath             => inline_template("<%= modulepath.join(':') %>"),
#    storedcofnigs          => 'true',
#    storeconfigs_dbserver  => 'master.puppetlabs.vm',
#  }
#
class puppet::master (
  $user_id                  = undef,
  $group_id                 = undef,
  $modulepath               = $::puppet::params::modulepath,
  $manifest                 = $::puppet::params::manifest,
  $report                   = true,
  $storeconfigs             = false,
  $storeconfigs_dbserver   =  $::puppet::params::storeconfigs_dbserver,
  $storeconfigs_dbport      = $::puppet::params::storeconfigs_dbport,
  $certname                 = $::fqdn,
  $autosign                 = false,
  $reporturl                = 'UNSET',
  $puppet_site              = $::puppet::params::puppet_site,
  $puppet_ssldir            = $::puppet::params::puppet_ssldir,
  $puppet_docroot           = $::puppet::params::puppet_docroot,
  $puppet_vardir            = $::puppet::params::puppet_vardir,
  $puppet_passenger_port    = $::puppet::params::puppet_passenger_port,
  $puppet_master_package    = $::puppet::params::puppet_master_package,
  $puppet_master_service    = $::puppet::params::puppet_master_service,
  $version                  = 'present',
  $apache_serveradmin       = $::puppet::params::apache_serveradmin
) inherits puppet::params {

  if ! defined(User[$::puppet::params::puppet_user]) {
    user { $::puppet::params::puppet_user:
      ensure => present,
      uid    => $user_id,
      gid    => $::puppet::params::puppet_group,
    }
  }

  if ! defined(Group[$::puppet::params::puppet_group]) {
    group { $::puppet::params::puppet_group:
      ensure => present,
      gid    => $group_id,
    }
  }

  if ! defined(Package[$puppet_master_package]) {
    package { $puppet_master_package:
      ensure   => $version,
    }
  }

  class {'puppet::passenger':
    puppet_passenger_port  => $puppet_passenger_port,
    puppet_docroot         => $puppet_docroot,
    apache_serveradmin     => $apache_serveradmin,
    puppet_site            => $puppet_site,
    puppet_conf            => $::puppet::params::puppet_conf,
    puppet_ssldir          => $::puppet::params::puppet_ssldir,
    certname               => $certname,
  }

  service { $puppet_master_service:
    ensure    => stopped,
    enable    => false,
    require   => File[$::puppet::params::puppet_conf],
    subscribe => Package[$puppet_master_package],
  }

 if ! defined(File[$::puppet::params::puppet_conf]) {
    file { $::puppet::params::puppet_conf:
      ensure  => 'file',
      mode    => '0644',
      require => File[$::puppet::params::confdir],
      owner   => $::puppet::params::puppet_user,
      group   => $::puppet::params::puppet_group,
      notify  => Service['httpd'],
    }
  }
  else {
    if $puppet_run_style == 'service' {
      File<| title == $::puppet::params::puppet_conf |> {
         notify  => Service['httpd'],
      }
    }
  }

  if ! defined(File[$::puppet::params::confdir]) {
    file { $::puppet::params::confdir:
      ensure  => directory,
      require => Package[$puppet_master_package],
      owner   => $::puppet::params::puppet_user,
      group   => $::puppet::params::puppet_group,
      notify  => Service['httpd'],
    }
  }
  else {
    File<| title == $::puppet::params::confdir |> {
      notify  +> Service['httpd'],
      require +> Package[$puppet_master_package],
    }
  }

  file { $puppet_vardir:
    ensure       => directory,
    owner        => $::puppet::params::puppet_user,
    group        => $::puppet::params::puppet_group,
    notify       => Service['httpd'],
    require      => Package[$puppet_master_package]
  }

  if $storeconfigs {
    class { 'puppet::storeconfigs':
      dbserver        => $storeconfigs_dbserver,
      dbport          => $storeconfigs_dbport,
      puppet_service  => Service['httpd'],
      puppet_confdir  => $::puppet::params::puppet_confdir,
      puppet_conf     => $::puppet::params::puppet_conf,
    }
  }
  
  ini_setting {'puppetmastermodulepath':
    ensure  => present,
    section => 'master',
    setting => 'modulepath',
    path    => $::puppet::params::puppet_conf,
    value   => $modulepath,
    require => File[$::puppet::params::puppet_conf],
  }
  
  ini_setting {'puppetmastermanifest':
    ensure  => present,
    section => 'master',
    setting => 'manifest',
    path    => $::puppet::params::puppet_conf,
    value   => $manifest,
    require => File[$::puppet::params::puppet_conf],
  }

  ini_setting {'puppetmasterautosign':
    ensure  => present,
    section => 'master',
    setting => 'autosign',
    path    => $::puppet::params::puppet_conf,
    value   => $autosign,
    require => File[$::puppet::params::puppet_conf],
  }

  ini_setting {'puppetmastercertname':
    ensure  => present,
    section => 'master',
    setting => 'certname',
    path    => $::puppet::params::puppet_conf,
    value   => $certname,
    require => File[$::puppet::params::puppet_conf],
  }

  ini_setting {'puppetmasterreport':
    ensure  => present,
    section => 'master',
    setting => 'report',
    path    => $::puppet::params::puppet_conf,
    value   => $report,
    require => File[$::puppet::params::puppet_conf],
  }

  if $reporturl != 'UNSET'{
    ini_setting {'puppetmasterreport':
      ensure  => present,
      section => 'master',
      setting => 'reporturl',
      path    => $::puppet::params::puppet_conf,
      value   => $reporturl,
      require => File[$::puppet::params::puppet_conf],
    }
  }
}