# Flutter Infrastructure Foundation

The Flutter Infrastructure Foundation Team is responsible for setting up, maintaining and improving the low level infrastructure used to build, test and release Flutter.


## DeviceLab Hardware

Flutter keeps a lab of test beds that include hosts and phones for all the supported platforms. These test beds are used to collect performance benchmarks and detect regressions.

As of May 2023 the Flutter DeviceLab contains 99 test beds with the following hardware and software:


<table>
  <tr>
   <td><strong>Host</strong>
   </td>
   <td><strong>Architecture</strong>
   </td>
   <td><strong>Phone</strong>
   </td>
   <td><strong>Count</strong>
   </td>
  </tr>
  <tr>
   <td>Linux
   </td>
   <td>X64
   </td>
   <td>Android
   </td>
   <td>36
   </td>
  </tr>
  <tr>
   <td>Windows
   </td>
   <td>X64
   </td>
   <td>Android
   </td>
   <td>6
   </td>
  </tr>
  <tr>
   <td>Windows
   </td>
   <td>Arm64
   </td>
   <td>Android
   </td>
   <td>1
   </td>
  </tr>
  <tr>
   <td>Windows
   </td>
   <td>Arm64
   </td>
   <td>
   </td>
   <td>9
   </td>
  </tr>
  <tr>
   <td>Mac
   </td>
   <td>X64
   </td>
   <td>iOS
   </td>
   <td>18
   </td>
  </tr>
  <tr>
   <td>Mac
   </td>
   <td>X64
   </td>
   <td>
   </td>
   <td>2
   </td>
  </tr>
  <tr>
   <td>Mac
   </td>
   <td>Arm64
   </td>
   <td>iOS
   </td>
   <td>12
   </td>
  </tr>
  <tr>
   <td>Mac
   </td>
   <td>Arm64
   </td>
   <td>
   </td>
   <td>1
   </td>
  </tr>
  <tr>
   <td>Mac
   </td>
   <td>X64
   </td>
   <td>Android
   </td>
   <td>9
   </td>
  </tr>
  <tr>
   <td>Mac
   </td>
   <td>Arm64
   </td>
   <td>Android
   </td>
   <td>5
   </td>
  </tr>
</table>



## VMs

Flutter uses Linux and Windows virtual machines to build and test Flutter. These VMs are auto-provisioned and distributed to 4 different pools. The following is the configuration distribution:


<table>
  <tr>
   <td style="background-color: null"><strong>LUCI pool</strong>
   </td>
   <td style="background-color: null"><strong>config</strong>
   </td>
   <td style="background-color: null"><strong>os</strong>
   </td>
   <td style="background-color: null"><strong>cpus</strong>
   </td>
   <td style="background-color: null"><strong>count</strong>
   </td>
   <td style="background-color: null"><strong>total cpus</strong>
   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.prod
   </td>
   <td style="background-color: null">e2-standard-32
   </td>
   <td style="background-color: null">Linux
   </td>
   <td style="background-color: null"><p style="text-align: right">
32</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
15</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
480</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.prod
   </td>
   <td style="background-color: null">n1-standard-8
   </td>
   <td style="background-color: null">Linux
   </td>
   <td style="background-color: null"><p style="text-align: right">
8</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
135</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
1080</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.try
   </td>
   <td style="background-color: null">e2-standard-32
   </td>
   <td style="background-color: null">Linux
   </td>
   <td style="background-color: null"><p style="text-align: right">
32</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
30</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
960</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.try
   </td>
   <td style="background-color: null">n1-standard-8
   </td>
   <td style="background-color: null">Linux
   </td>
   <td style="background-color: null"><p style="text-align: right">
8</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
137</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
1096</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.staging
   </td>
   <td style="background-color: null">e2-standard-32
   </td>
   <td style="background-color: null">Linux
   </td>
   <td style="background-color: null"><p style="text-align: right">
32</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
4</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
128</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.staging
   </td>
   <td style="background-color: null">n1-standard-8
   </td>
   <td style="background-color: null">Linux
   </td>
   <td style="background-color: null"><p style="text-align: right">
8</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
30</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
240</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.dart-internal.flutter
   </td>
   <td style="background-color: null">e2-standard-32
   </td>
   <td style="background-color: null">Linux
   </td>
   <td style="background-color: null"><p style="text-align: right">
32</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
20</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
640</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.prod
   </td>
   <td style="background-color: null">e2-highmem-8
   </td>
   <td style="background-color: null">Windows
   </td>
   <td style="background-color: null"><p style="text-align: right">
8</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
59</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
472</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.try
   </td>
   <td style="background-color: null">e2-highmem-8
   </td>
   <td style="background-color: null">Windows
   </td>
   <td style="background-color: null"><p style="text-align: right">
8</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
130</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
1040</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.staging
   </td>
   <td style="background-color: null">e2-highmem-8
   </td>
   <td style="background-color: null">Windows
   </td>
   <td style="background-color: null"><p style="text-align: right">
8</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
12</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
96</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.dart-internal.flutter
   </td>
   <td style="background-color: null">e2-highmem-8
   </td>
   <td style="background-color: null">Windows
   </td>
   <td style="background-color: null"><p style="text-align: right">
8</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
20</p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
160</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">
   </td>
   <td style="background-color: null">
   </td>
   <td style="background-color: null">
   </td>
   <td style="background-color: null">
   </td>
   <td style="background-color: null">
   </td>
   <td style="background-color: null">
   </td>
  </tr>
  <tr>
   <td style="background-color: null"><strong>Totals</strong>
   </td>
   <td style="background-color: null">
   </td>
   <td style="background-color: null">
   </td>
   <td style="background-color: null">
   </td>
   <td style="background-color: null"><p style="text-align: right">
<strong>592</strong></p>

   </td>
   <td style="background-color: null"><p style="text-align: right">
<strong>6392</strong></p>

   </td>
  </tr>
</table>



## Mac hostonly machines

Mac machines are organized in a different category because they are provisioned in chrome labs and have no phones attached. The machine configurations are the following:


<table>
  <tr>
   <td style="background-color: null"><strong>LUCI pool</strong>
   </td>
   <td style="background-color: null"><strong>model</strong>
   </td>
   <td style="background-color: null"><strong>os</strong>
   </td>
   <td style="background-color: null"><strong>count</strong>
   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.prod
   </td>
   <td style="background-color: null">Macmini8,1
   </td>
   <td style="background-color: null">Mac-12.6-21G115
   </td>
   <td style="background-color: null"><p style="text-align: right">
28</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.prod
   </td>
   <td style="background-color: null">Macmini9,1
   </td>
   <td style="background-color: null">Mac-12.6-21G115
   </td>
   <td style="background-color: null"><p style="text-align: right">
31</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.try
   </td>
   <td style="background-color: null">Macmini8,1
   </td>
   <td style="background-color: null">Mac-12.6-21G115
   </td>
   <td style="background-color: null"><p style="text-align: right">
74</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.try
   </td>
   <td style="background-color: null">Macmini9,1
   </td>
   <td style="background-color: null">Mac-12.6-21G115
   </td>
   <td style="background-color: null"><p style="text-align: right">
71</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.staging
   </td>
   <td style="background-color: null">Macmini8,1
   </td>
   <td style="background-color: null">Mac-12.6-21G115
   </td>
   <td style="background-color: null"><p style="text-align: right">
5</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.flutter.staging
   </td>
   <td style="background-color: null">Macmini9,1
   </td>
   <td style="background-color: null">Mac-12.6-21G115
   </td>
   <td style="background-color: null"><p style="text-align: right">
7</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.dart-internal.flutter
   </td>
   <td style="background-color: null">Macmini8,1
   </td>
   <td style="background-color: null">Mac-12.6-21G116
   </td>
   <td style="background-color: null"><p style="text-align: right">
15</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">luci.dart-internal.flutter
   </td>
   <td style="background-color: null">Macmini9,1
   </td>
   <td style="background-color: null">Mac-12.6-21G117
   </td>
   <td style="background-color: null"><p style="text-align: right">
2</p>

   </td>
  </tr>
  <tr>
   <td style="background-color: null">
   </td>
   <td style="background-color: null">
   </td>
   <td style="background-color: null">
   </td>
   <td style="background-color: null">
   </td>
  </tr>
  <tr>
   <td style="background-color: null"><strong>Totals</strong>
   </td>
   <td style="background-color: null">
   </td>
   <td style="background-color: null">
   </td>
   <td style="background-color: null"><p style="text-align: right">
<strong>233</strong></p>

   </td>
  </tr>
</table>



## Services

Flutter Infrastructure Foundation owns the DeviceLab provisioning services, maintains Flutter LUCI service configurations, and provides lab maintenance services.

This is the list of services with their descriptions:


<table>
  <tr>
   <td><strong>Service</strong>
   </td>
   <td><strong>Type</strong>
   </td>
   <td><strong>Description</strong>
   </td>
  </tr>
  <tr>
   <td>SALT
   </td>
   <td>Owned
   </td>
   <td>Configuration provisioning service used to push configurations as code for host and devices for all the supported platforms.
   </td>
  </tr>
  <tr>
   <td>Machine Provider
   </td>
   <td>Configuration management
   </td>
   <td>Configuration service to provision, spin up and tear down virtual machines.
   </td>
  </tr>
  <tr>
   <td>LUCI swarming bot
   </td>
   <td>Owned
   </td>
   <td>Scripts used to set up and tear down LUCI services on the supported platforms.
   </td>
  </tr>
  <tr>
   <td>Capacity planning and delivery
   </td>
   <td>Owned
   </td>
   <td>Budgeting for lab expansions, delivery of new capacity, and decommissioning of end of life hardware.
   </td>
  </tr>
  <tr>
   <td>Lab maintenance
   </td>
   <td>Owned
   </td>
   <td>Faulty hardware replacement, hardware recovery and reprovisioning.
<p>
Lab migrations planning and execution.
   </td>
  </tr>
  <tr>
   <td>Onboarding of new platforms
   </td>
   <td>Owned
   </td>
   <td>Creating provisioning SALT scripts and onboarding on LUCI services.
   </td>
  </tr>
  <tr>
   <td>Device doctor
   </td>
   <td>Owned
   </td>
   <td>Phone configuration validation and device recovery.
   </td>
  </tr>
</table>