## Library Powered By

This library is powered by [Entity Framework Extensions](https://entityframework-extensions.net/?z=github&y=entityframework-plus)

<a href="https://entityframework-extensions.net/?z=github&y=entityframework-plus">
<kbd>
<img src="https://zzzprojects.github.io/images/logo/entityframework-extensions-pub.jpg" alt="Entity Framework Extensions" />
</kbd>
</a>

---

SQL Fiddle
==========

See [the SQL Fiddle about page](http://sqlfiddle.com/about.html) page for background on the site.

## Getting the project up and running

Fork the code on github to a local branch for youself.

You are going to need [Vagrant](http://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/) installed locally to get SQL Fiddle running. For VirtualBox, you will need to add a Host-only network for 10.0.0.0/24. Once you those installed and configured, and this project cloned locally, run this command from the root of your working copy:

    vagrant up

This will take a while to download the base image and all of the many dependencies. Once it has finished, you will have the software running in a set of VMs. You can now access your local server at [localhost:6081](http://localhost:6081/).

Note for Windows users - be sure that you run "vagrant up" as an administrator.

You should now have a functional copy of SQL Fiddle running locally.

I'm happy to entertain pull requests!

Thanks, 
Jake Feasel


## Commercial software requirements

To run the commercial database software (Microsoft SQL Server 2014 Express, Oracle 11g R2 XE) you must have a Windows Server 2008 R2 (or higher) instance available, preferably as a Vagrantbox. The core software must be installed prior to attempting to use it with SQL Fiddle. Below are the expectations for how this Vagrantbox image needs to be produced

### Windows 2008 Server Requirements
1) Install Windows in a Virtualbox VM
2) Install the database software within this VM (see below sections for details)
3) Follow the instructions listed on [this blog post to turn it into a Vagrantbox](http://dennypc.wordpress.com/2014/06/09/creating-a-windows-box-with-vagrant-1-6/)
4) Update the Vagrantfile located in this folder to refer to your own Vagrantbox image (replace /Volumes/Virtual Disk Storage/jakefeasel.windows2008R2SQLServer2014Oracle11GXE.box with the path to your image)
5) Before you type vagrant up, you will need to type "vagrant up windows" to start this VM, since it is optional

### SQL Server 2014 Express

1) Don't need the "SQL Server Replication" Feature (leave the others checked)
2) Use the "Default instance" (leave the "Instance ID" as "MSSQLSERVER")
3) Authentication mode is "Mixed"; sa password is "SQLServerPassword"
4) Enable TCP/IP connections in the network configuration


### Oracle 11g R2 XE
1) "system" password is "password"
2) Follow instructions in vagrant_scripts/idm_bootstrap.sh for details on what must be done to obtain and use the JDBC driver


## Running on AWS

With a bit of preparation, you should be able to deploy the whole app into Amazon Web Services. See the comments in Vagrantfile for an example config that you can fill in with your own AWS account details. For MS SQL and Oracle support, you will have to create your own AMI with Windows, following the same steps mentioned above.

You will need to install the vagrant-aws plugin. See the plugin site here for details: https://github.com/mitchellh/vagrant-aws

Be sure to also install the "dummy" box.

You may also wish to have automated backups of your sqlfiddle database to S3. If so, you will need to add a .s3cfg file under vagrant_scripts. This file will not be added to the git repo (it is ignored) but if present the PostgreSQL server will automatically schedule backups to write to your account. The .s3cfg file is produced by "s3cmd" - check this site for more details: http://s3tools.org/s3cmd-howto

## Contribute

The best way to contribute is by **spreading the word** about the library:

 - Blog it
 - Comment it
 - Star it
 - Share it
 
A **HUGE THANKS** for your help.

## More Projects

- Projects:
   - [EntityFramework Extensions](https://entityframework-extensions.net/)
   - [Dapper Plus](https://dapper-plus.net/)
   - [C# Eval Expression](https://eval-expression.net/)
- Learn Websites
   - [Learn EF Core](https://www.learnentityframeworkcore.com/)
   - [Learn Dapper](https://www.learndapper.com/)
- Online Tools:
   - [.NET Fiddle](https://dotnetfiddle.net/)
   - [SQL Fiddle](https://sqlfiddle.com/)
   - [ZZZ Code AI](https://zzzcode.ai/)
- and much more!

To view all our free and paid projects, visit our website [ZZZ Projects](https://zzzprojects.com/).
