# Rapidly deploy and configure your Java applications with WebSphere Liberty and OpenShift Container Platform

![banner](./images/media/image1.jpeg) 

**Last updated:** September 2026

**Status: ** DRAFT - work in progress

**Duration:** 60 minutes

Need support? Contact **Lars Besselmann, Sebastian Porro**

## Overview
This lab provides fundamental hands-on experience with modernizing existing Java applications to WebSphere Liberty, deployed into a container platform, such as Red Hat OpenShift. 

The focus of this lab is on the practical aspects of application deployment and configurations and not the analysis of the Application Modernization Accelerator results. *Other labs cover Application Modernization Accelerator in detail.*

Upon completion of this lab, you will have gained skills to download and use the `Application Modernization Accelerator migration plan` to deploy and configure your application in the following scenarios: 

1.  **to a locally running WebSphere Liberty** - useful for deploying to Liberty in a VM

2.  **to a container image** – useful for deploying to Kubernetes

3.  **using the Liberty Operator** – useful for deploying to OpenShift


**IBM Application Modernization Accelerator** (Application Modernization Accelerator) is an application modernization tool that helps you quickly evaluate on-premises Java EE applications for deployment to the cloud. 

The Application Modernization Accelerator tool provides the following value:

  - Identifies the Java EE programming models in the app

  - Determines the complexity of replatforming these apps by listing a high-level inventory of the content and structure of each app

  - Highlights Java EE programming model and WebSphere API differences between the WebSphere runtime profile types 

  - Identifies Java EE specification implementation differences that might affect the app

  - Generates accelerators for deploying the application to Liberty and containers in a target environment

Additionally, the tool provides a recommendation for the right-fit IBM WebSphere Application Server edition and offers advice, best practices, and potential solutions to assess the ease of moving apps to Liberty or newer versions of WebSphere traditional. It accelerates application migrating to cloud process, minimizes errors and risks and reduces time to market.


## Objective

The objectives of this lab are to:

  - Learn how to download the application migration plan and use it to deploy an application to WebSphere Liberty running locally

  - Learn how to fully populate the migration plan placeholders and build the application into a container image

  - Learn the role of Kustomize when deploying the migration plan

  - Learn how to deploy your application to OpenShift with a single command

  - Learn how to create multiple configurations for the application and deploy them to OpenShift


## Prerequisites

The following prerequisites must be completed prior to beginning this lab:

  - Familiarity with basic Linux commands

  - Have internet access

  - Access to the TechZone lab environment

## Accessing the lab environment

If you are doing this lab as part of an instructor led workshop (virtual or face to face), an environment has already been provisioned for you. The instructor will provide the details for accessing the lab environment.

Otherwise, you will need to reserve an environment for the lab. You can obtain one here. Follow the on-screen instructions for the “**Reserve now**” option.

[https://techzone.ibm.com/my/reservations/create/65eb652a747d7a00108fb5db](https://techzone.ibm.com/my/reservations/create/65eb652a747d7a00108fb5db)

The lab environment contains six (6) Linux VMs.



## Lab Tasks

In this lab, you will use the Application Modernization Accelerator `migration plan` to build a container image and deploy an application to a local container for testing.

To simplify the lab and to allow you to focus on the migration plan, certain software and artifacts have already been put in place for you. These are as follows:

  - **Application Modernization Accelerator** has been installed and collected data has been loaded

  - **podman** (for creating and running images) has been installed

  - **oc** (OpenShift command Line tool for running OCP commands) has been installed

  - The **PlantsByWebSphere Sample Application**, built as an Enterprise Archive file (EAR) is available from the lab resource provided.

# Part 0: Prepare environment

**Disable docker**

    unalias docker
    sudo mv /bin/docker /bin/docker.sav


**Install AMA**

    /tmp/post_deploy_repo/scripts/AMA_510_install.sh
    sh ~/software/AMA/AMA_apply_Full_Key.sh 

**Move/remove files to backup**

    mkdir ~/backup
    mv ~/Student ~/backup
    rm -rf ~/binary-scanner
    rm -rf ~/IBM
    rm -rf ~/transformation-advisor-local-3.8.1

**Create Student directory**

    mkdir -p ~/Student/temp

** Clone the project repository

    git clone https://github.com/LarsBesselmann/Liberty-Getting-Started-OCP ~/Student/temp
    mv ~/Student/temp/lab_sources/* ~/Student
    rm -rf ~/Student/temp
    ls -lrt ~/Student
    

**Create podman container with the PlantsByWebSphere database pbwdb**

    cd ~/Student

    ## Needs sudo for DB2 (rootless not allowed)

    sudo podman build -t plantsdb-db2 ./plantsdb-db2

    sudo podman run --privileged=true -d \
    --name plantsdb-db2 \
    -p 50000:50000 \
    -e LICENSE=accept \
    -e DB2INST1_PASSWORD=db2password \
    -e DBNAME=PLANTSDB \
    -v plantsdb-data:/database \
    plantsdb-db2

    netstat -an | grep 50000


# Part 1: Application Assesment    

## 1.1 Launch Application Modernization Accelerator (local)

Application Modernization Accelerator provides a **`migration plan`** for each application being assessed for modernization. The migration plan includes a **`migration plan`** of generated artifacts that accelerate the deployment of applications to Liberty in containers and Kubernetes / OpenShift.

The migration plan includes diverse artifacts, depending on the needs of the application to accelerate the build and deployment of an application Container image into an OpenShift container platform.

The Application Modernization Accelerator is installed locally on the **Workstation** VM. 

1. Launch the Application Modernization Accelerator tool using the steps below.

    a.  From **Workstation** VM Desktop Tool Bar, click the `Terminal` icon to open a Terminal window.

    b.  Launch the **Application Modernization Accelerator** with commands:

        cd ~/usr/IBM/application-modernization-accelerator-local-*

        ./launch.sh
        
     Wait for Application Modernization Accelerator to initialize and display the **action menu** list.

    c.  If not already started, type **`5`** and press **`Enter`** to “Start” the **Application Modernization Accelerator**.

     ![](./images/media/image12.png)
 
    d. The **Application Modernization Accelerator** application is started, **`right-click`** the application URL link and select **`Open Link`** to launch it in a web browser window.
 
     The URL is displayed in the output from the AMA command: [**https://localhost:3000**]
 
     ![](./images/media/image13.png)
 

    e. Accept the security warning

     ![](./images/media/image13a.png)
 
 
    f. Accept all cookies

     ![](./images/media/image13b.png)
 
    

     The **Application Modernization Accelerator** Home page is displayed in the Web Browser.
 
     ![](./images/media/image14.png)

    In the next section, you will create a new “**Workspace**” in Application Modernization Accelerator and upload the saved results from the scan of a WebSphere Application Server that has a single application deployed, named “PlantsByWebSphere”.


## 1.3 Create new workspace and upload scan results from a WebSphere Application Server

In this section, create a new workspace named **'Evaluation'**.

A `workspace` is a designated area that will house the migration recommendations provided by Application Modernization Accelerator based on the Data Collector scan results of your application server environment.

1. Create a new workspace named **Evaluation**

    a.  From the Application Modernization Accelerator Home page, click the **`Create New`** button

    b.  Type **`Evaluation`** as the Workspace name. Then click the **`Create`** button

     ![screenshot](./images/media/image15.png)

2. Upload an existing **'scan results'** file provided for the lab.

    The scan results file is provided for you.

    It was produced by running the Application Modernization Accelerator **Data Collector** on a WebSphere Application Server that had the **PlantsByWebSphere** application deployed.

    a. Click the **`Upload results`** button

    ![Upload results](./images/media/image16.png)


    b. Click the **`Drop or add file`** link. Then click the **`Upload`** button

    ![Upload results](./images/media/image16a.png)


    
    c.  Navigate to **Home \> itzuser \> Student \> AMA**

    d.  Select **`Dmgr.zip`** file. Then click the **`Open`** button

    ![Upload data collection](./images/media/image17.png)

    e. Once the **Dmgr.zip** has been added, click on the **`Upload`** button to upload the results into Application Modernization Accelerator.

    ![Upload data collection](./images/media/image18.png)

    After a few moments, the application data will be uploaded to the Application Modernization Accelerator UI. You will be asked to select the target runtime. Select **Liberty** and click on **Confirm**.

    ![Upload data collection](./images/media/image18a.png)

    
    The "**Evaluation**" workspace displays the “Visualization** of all applications in that workspace. The application you will focus on in the lab is the PlantsByWebSphere application which consists of an application server and a database.

    ![AMA_Visualization_View](./images/media/image18c.png)

    
    Click on **Assessment** to see more details about the different applications.

    ![AMA_Assessment_View](./images/media/image19.png)


    There is a single application called **plantsbywebsphereee6.ear**. 
    
    


## 1.4 Analyze the plantsbywebsphereee6 application

 Application Modernization Accelerator provides detailed information about each application that has been analyzed. This application has a complexity of **`Simple`**.
 
 **Simple** means:
 
  - The application is ready to be deployed to WebSphere Liberty
  - No changes to the source code are required
 
   
![screenshot](./images/media/image20.png)

 ***How is this application ready for deployment when it shows 4 issues?***
 
 In this case, the application has four **`Informational`** issues.
 
 Informational issues do not prevent the application from executing on the new runtime (WebSphere Liberty) but there may be small changes in the application’s behavior.
 
 If unexpected behavior is found during testing, then reviewing these **Informational** issues may help explain what is happening.

1.  We are now ready to review the **'migration plan'** for this application. 

    a. Click on the **`Migration plan`** link at the end of the row of the **plantsbywebsphereee6.ear** application.

    ![screenshot](./images/media/image21.png)

    b.  The **Migration Plan** page opens.

    This page contains a summary of the application being migrated:

    - a preview of the files that will help during deployment (highlighted below)

    - a list of the application’s dependencies.

    All the files can be downloaded in a single convenient **migration plan**.

    ![](./images/media/image22.png)

2. At the bottom of the screen, there is a `Application Dependencies` section. 
    
    This shows all the files, in addition to the application, that are required for a deployment. **Plantsbywebspheeee6.ear** has two dependencies.

    a. Expand the section it to see the details

    b. In this case, DB2 drivers called **db2jcc.jar** and **db2cc_licence.jar** are required for deployment (you might see additional libraries but those are not required in that case.)

    ![PBW depdencencies](./images/media/image23.png)

3.  Download the migration plan by clicking the **`Download plan`** button in the bottom right. 

    ![screenshot](./images/media/image24.png)

    If you get a security warning, accept the risk and continue.

    ![screenshot](./images/media/image24_alert.png)
    

    A zip file named “**plantsbywebsphereee6.ear_migrationPlan.zip**” will download to your **Download** folder.



We will go through a step-by-step process of using the Application Modernization Accelerator migration plan to deploy **plantsbywebsphereee6.ear** as follows:

  1. Ensure the application can run locally on WebSphere Liberty

  2. Build an immutable container image running on WebSphere Liberty

  3. Deploy the image to OpenShift (and configure it) using a single command

  4. Redeploy and reconfigure this image for a new environment with a single command

# Part 2: Deploy PlantsByWebSphere app to a locally running WebSphere Liberty    

In this step, you will create a new Liberty server to run the PlantsByWebSphere application.

Then, you will review the migration plan to see what files you need to add, and use the provided `server.xml` Liberty configuration file. This file is used to configure Liberty by providing values for ports, security, context routes and by providing application-specific configuration. 

### 2.1   Create a local Liberty Server

1.  From a **`Terminal`** window, download and install the Liberty archive.

        wget https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/wasdev/downloads/wlp/26.0.0.6/wlp-javaee7-26.0.0.6.zip -P ~/Student
        cd ~/Student
        unzip wlp-javaee7-26.0.0.6.zip


    

2.  From the **`Terminal`** window, create a new local WebSphere Liberty server named ‘**pbwserver**”

        ~/Student/wlp/bin/server create pbwserver

    **output:**

    ```
    Server pbwserver created.
    ```
3.  From the **Terminal** window, start the local WebSphere Liberty server.

        ~/Student/wlp/bin/server start pbwserver

    **Output:**

    ```
    Starting server pbwserver.

    Server pbwserver started with process ID #####
    ```

4.  Confirm the local WebSphere Liberty server is running. Open the `Firefox` web browser, open a new browser tab. Then go to: **http://localhost:9080**

    ![screenshot](./images/media/image25.png)


5.  From the **Terminal** window, stop the local WebSphere Liberty server.

        ~/Student/wlp/bin/server stop pbwserver

    **Output:**

    ```
    Stopping server pbwserver.
    Server pbwserver stopped.

    ```



### 2.1.3 Review the placeholder files in the migration plan

In this section, you will review the migration plan to see what files need to be added to the WebSphere Liberty configuration to run the application. 

1.  Let’s make note of the 3 `placeholder files` that are placed in the `migration plan`.

    The placeholder files are convenient references to let you know which files you will need to copy to the **Liberty server**.
 
    *Note: You will fully populate the migration plan in later steps*.

    a.  From the **Terminal window**, list the placeholder files in the migration plan.

        unzip -l ~/Downloads/plantsbywebsphereee6.ear_migrationPlan.zip | grep placeholder
 
    ![](./images/media/placeholder-files.png)
 
    - The **`target`** directory contains the placeholder file for the PlantsByWebSphere application EAR deployment file. This is a reminder that you need to copy the PlantsByWebSphere EAR file the Liberty server.

    - The **`src/main/liberty/lib`** directory contains the placeholder files for the DB2 database libraries required by the application. This is a reminder that you need to copy the DB2 libraries to the Liberty server.

    <br/>

### 2.1.4   Configure the Liberty server for PlantsByWebSphere

In this section, extract the migration plan that you downloaded. Then, copy the required dependency files and server configuration to the Liberty server.

  - Extract the **migration plan** to a new directory

  - Copy the **DB2 libraries** to the directory defined in the "DB2 driver configuration" in the server.xml file.

  - Copy the **PlantsByWebSphere EAR** file to the “apps” directory of the Liberty server

  - Copy the **server.xml** file from the migration plan to the Liberty server, replacing the default server.xml file


1. Extract the migration plan that you downloaded

        mkdir ~/Student/migrationPlan
        cd ~/Student/migrationPlan
        cp ~/Downloads/plantsbywebsphereee6.ear_migrationPlan.zip .
        unzip plantsbywebsphereee6.ear_migrationPlan.zip


2. List the directory of the extracted migration plan

        ls -l        

    The migration plan contains the files to build and deploy the PlantsByWebSphere application to Liberty, in containers, and on OpenShift.     

    ![](./images/media/migrationplan_content.png)
 

3.	Copy the PlantsByWebSphere application binary file into the `apps` location in Liberty

        cp ~/Student/plantsbywebsphereee6.ear ~/Student/wlp/usr/servers/pbwserver/apps

4. Create the `global shared` directory in Liberty. 

    This is where you will copy the DB2 libraries for Liberty

        mkdir -p ~/Student/wlp/usr/shared/config/lib/global
 
5.	Copy the DB2 driver files into the `global shared` location in Liberty.

    This will make it available to any application running in Liberty.

        cp ~/Student/db2_drivers/* ~/Student/wlp/usr/shared/config/lib/global

        ls -lrt ~/Student/wlp/usr/shared/config/lib/global



6.	Copy the `server.xml` file from the migration plan into the Liberty server to replace its existing configuration. Choose to overwrite the existing file if prompted.

        cp ~/Student/migrationPlan/src/main/liberty/config/server.xml ~/Student/wlp/usr/servers/pbwserver 

7.	Configure Liberty to use Java 8 instead of Java 21.

        echo "" >> ~/Student/wlp/usr/servers/pbwserver/server.env

        echo "JAVA_HOME=/usr/lib/jvm/ibm-semeru-open-8-jdk" >> ~/Student/wlp/usr/servers/pbwserver/server.env
 
8. Configure Liberty to use JPA 2.0 instead of JPA 2.1. 

        sed -i 's/jpa-2.1/jpa-2.0/g' /home/itzuser/Student/wlp/usr/servers/pbwserver/server.xml
    

9. Install the missing Liberty features required to run the application

        ~/Student/wlp/bin/featureUtility installServerFeatures pbwserver


    ___

    Now that the PlantsByWebSphere binary and its configuration are added to the Liberty server, the application is ready to be run from the web browser.     
    ___

9. Start the Liberty server

        ~/Student/wlp/bin/server start pbwserver --clean


10.  Run the PlantsByWebSphere application from the browser.

        http://localhost:9080/PlantsByWebSphere
 
        Now the application is running in Liberty, and the main page is displayed.
 
        ![A website page of a garden Description automatically generated](./images/media/image36.png)

11.  Attempt to click on any of the tabs: “**Flowers**”, **Fruits & Vegetables**”, or “**Trees**”.

12. **Note the exception.** This is an expected error. The issue is in the JPA persistence (Database access). A user is not defined, and therefore authentication to the database failed.
 
    ![A screen shot of a computer Description automatically generated](./images/media/image37.png)
 
    ___

    These pages should display a catalog of items in their respective category, which are retrieved from the application database. 

    **So what happened?** 
    
    Application Modernization Accelerator does not collect any `sensitive data` for the application server.  This means the application-specific configuration information in the **server.xml** file has not been set. In this case, the `username` and `password` to access the database are missing.

    In the next section, you will review the server.xml file and add the sensitive data required to access the application database.  

    <br/>

### 2.1.5   Review the server.xml file

Now you will review the **`server.xml`** file and set the necessary configuration information. 

The **server.xml** file defines a set of **`features`** that the application requires. By importing only the necessary **features** to support the application’s API needs, the footprint of the deployed application and Liberty server is kept as small as possible.

1. Review the server.xml file

    Using the “**`gedit`**” editor in a **`Terminal`** window, open the **server.xml** file located in the Liberty server

        gedit ~/Student/wlp/usr/servers/pbwserver/server.xml &

    - **Section 1** contains the `features` that the application requires, and these are discovered automatically during analysis performed by the Application Modernization Accelerator **Data Collector**.

      ![FeatureManager](./images/media/image38.png)

    - **Section 2:** Defines the `resources` required to access the database

      - The **`authdata`** defies the BD2 user and password that is used by the datasources. These refer to variables that are defined in the server.xml file.

      - The **`jdbc`** driver defines the required libraries. These are the libraries you copied into this location via the script

      ![database resources](./images/media/image39.png)

    - **Section 3:** The **`datasource`** contains all the information required to access the database: Database user, password, database name, host, and port number.

      ![datasource](./images/media/image40.png)


    - **Section 4** contains the variables for the **`non-sensitive configuration data`**. For example, the port to run the server on. The values of these variables are collected by Application Modernization Accelerator.

      ![non-sensitive config data](./images/media/image41.png)

    - **Section 5** contains the **`sensitive data variables`**. 
    
      You can see that the values for these variables are all **blank**, as this information is **never** collected by Application Modernization Accelerator.

      ![sensitive config data](./images/media/image42.png)


2.  The reason that the **PlantsByWebSphere** application returned an “Exception” is because the values for the **sensitive variables** have not been set - neither in the server.xml nor in the environment. 
  
    ![](./images/media/image43.png)

    Next, you will update the server.xml to include the credentials required to access the application database. 


### 2.1.6   Update the server.xml and retest the PlantsByWebSphere application


1. From a Terminal window, `stop` the Liberty server named ‘pbwserver”

        ~/Student/wlp/bin/server stop pbwserver

2. From the `gedit` editor that you have open, update the values in the **server.xml** file for the sensitive data as illustrtated below:

    a. Scroll to the bottom of the `server.xml` file to view the sensitive-data variables. 

    b.  Set the default value for **Dmgr01Node_DB2INST1_password** to: **`db2password`**
    
    c. Set the default value for **Dmgr01Node_DB2INST1_user** to: **`db2inst1`**

     ![](./images/media/image44.png)
    
    d. **`Save`** and **`close`** the server.xml in the editor

    e. You might have detected that the database host is defined in the server.xml as **vm-1** but now is located on the host **desktop-2**.
    Use the following command to replace it.

        sed -i 's/vm-1/desktop-2/g' /home/itzuser/Student/wlp/usr/servers/pbwserver/server.xml

3. From a Terminal window, `start` the Liberty server named ‘pbwserver”

        ~/Student/wlp/bin/server start pbwserver


4. Reload and test PlantsByWebSphere application in the browser

    http://localhost:9080/PlantsByWebSphere

    If you would now attempt to click on any of the tabs: “Flowers”, Fruits & Vegetables”, or “Trees”, you would see that the error has gone but you would see another error like this as the database has not been initialized yet..

    ![PBW Error not init](./images/media/pbw_dB_not_initialized.png)
    
    Therefore before we can fully test the application, we need to initialize the database.

    a. Click on Help to get the help panel

    ![PBW Help](./images/media/pbw-help.png)
    
    b. Click on the **Reset database** button to reset the database.

    ![PBW Reset Database](./images/media/pbw-reset-database.png)

    c. Back on the main page, click the “**Flowers**” tab. The catalog of flowers should now be displayed.

    ![PBW Flowers](./images/media/image45.png)


3. From a **Terminal** window, `Stop` the Liberty server named ‘**pbwserver**”

        ~/Student/wlp/bin/server stop pbwserver


### Checkpoint

At this point in the lab, you have successfully demonstrated the PlantsByWebSphere application runs successfully in WebSphere Liberty on a local VM. 

In the next sections, you will deploy the PlantsByWebSphere application to containers and Red Hat OpenShift. 

# Part 3: Create and run the PlantsByWebSphere application as a container image    


## 3.1  Explore the Containerfile used to build PlantsByWebSphere as a container image

In the previous section, you used the **server.xml** to get the  application running on a `local Liberty instance`. This was to show you how the Application Modernization Accelerator **server.xml** file is used. If you are moving to Liberty in VMs as your new runtime, then you are done! 

However if containers are to be your final destination, this section explores the Application Modernization Accelerator migration plan artifacts that accelerate application deployment to Liberty in containers. 

In the case of **`Simple`** applications, it is not necessary to carry out a separate step of deploying to a local Liberty instance at all. Instead, by using the Application Modernization Accelerator migration plan, you can deploy your application to **Liberty running in a container** all in one go. 

This is what we will do now.


1.	Add the PlantsByWebSphere binary file to your migration plan, and remove the placeholder.

        cp ~/Student/plantsbywebsphereee6.ear ~/Student/migrationPlan/target

        rm ~/Student/migrationPlan/target/plantsbywebsphereee6.ear.placeholder


2.	Add the db2 library files to your migration plan, and remove the placeholder.

        cp ~/Student/db2_drivers/* ~/Student/migrationPlan/src/main/liberty/lib  

        rm ~/Student/migrationPlan/src/main/liberty/lib/*.placeholder

3.	Update the server.xml file as before to adjust the database endpoint and JPA spec. 

        sed -i 's/vm-1/desktop-2/g' /home/itzuser/Student/migrationPlan/src/main/liberty/config/server.xml
        sed -i 's/jpa-2.1/jpa-2.0/g' /home/itzuser/Student/migrationPlan/src/main/liberty/config/server.xml


4.  Modify the "**Containerfile**" to specify a specific version of Liberty to deploy: in this case, **icr.io/appcafe/websphere-liberty:26.0.0.6-kernel-java8-openj9-ubi**

        sed -i 's/websphere-liberty:25.0.0.6-kernel-java8-openj9-ubi/websphere-liberty:26.0.0.6-kernel-java8-openj9-ubi/g' /home/itzuser/Student/migrationPlan/Containerfile


5. The `migration plan` is ready to be used to generate an image of your application running on WebSphere Liberty. To do this, we will use the **`Containerfile`** that comes with the migration plan.


    a. Explore the Containerfile in the migration plan

        gedit /home/itzuser/Student/migrationPlan/Containerfile
 
 
    - The **FROM** statements in the **Containerfile** pull in the following two images. 
     
      - **`Open JDK 8`**
      - **Latest `WebSphere Liberty`**

      ![](./images/media/image50.png)

      ![](./images/media/image51.png)

       
    - The **RUN** commands in the Containerfile create the necessary folder structures and copies the **`binary files`** from the migration plan into the appropriate locations in the image.

      ![Containerfile-RUN](./images/media/image52.png)

    - There are several lines in the file that have been commented out. 
    
      By default, the **Containerfile** assumes that your application is available as a **binary** file. However, it can also be used to build your application from **source** code. The full details of how to do this can be found in **README.md** in the migration plan.

      ![](./images/media/image53.png)

    b. `Close` the "gedit" editor. **DO NOT SAVE ANY CHNAGES TO THE FILE!** 

    <br/>


### 3.2 Setup, build and run PlantsByWebSphere in a local container

In this section, you will build and run the PlantsByWebSphere application in a local container.

1.	Build the container image from the migration plan using podman

        cd ~/Student/migrationPlan

        podman build -f Containerfile --tag apps/pbw .

    - `-f` is the path to the `Containerfile` used to build the image
    - `--tag` allows you to define the name and version of the image to build
    - `.` is the "current directory" of the migration plan that includes the artifacts for building the container image. 

    
2. Confirm the container image has been built

        podman images | grep apps/pbw


    ![](./images/media/pbw-image-listed.png)


3.	The next step is to run the image using the `podman run`command.

        podman run -d --rm -p 9080:9080 --name pbw-app  apps/pbw

    -  `-d` start the container in 'detached' mode so you get your command prompt back
    -  `--rm` remove the container when it is stopped
    -  `-p` expose the HTTP port
    - `--network` connect the container to the same podman network as the DB2 container
    -  `--name` is the name we are giving the container 


4.	Check that the contaier is up and running. 

        podman ps | grep pbw-app

    ![](./images/media/pbw-app-up.png)



5.  From the browser, access the PlantsByWebSphere application that is running in the local container:

    http://localhost:9080/PlantsByWebSphere
 
     ![PBW](./images/media/image61.png)
 
    
    Attempt to click on any of the tabs: “**Flowers**”, **Fruits & Vegetables**”, or “**Trees**”.

    ___

    **Note the exception.** This is an expected error. The issue is in the JPA persistence (Database access). A user is not defined, and therefore authentication to the database failed.
 
    ![](./images/media/pbw-container-db-error.png)
 
    The error is because we are using the unchanged server.xml file that came with the migration plan. 
    
    As outlined already, Application Modernization Accelerator does not collect any sensitive data so the application specific configuration information has not been set. 

6. To make sure the container as is works, let's inject the credentials via environment variables. Restart the container but with slightly different parameters. (This approach is not recommended for production accounts)

        podman stop pbw-app

        podman run -d --rm -p 9080:9080 -e Dmgr01Node_DB2INST1_password="db2password" -e Dmgr01Node_DB2INST1_user="db2inst1" --name pbw-app  apps/pbw 

7.  From the browser, access the PlantsByWebSphere application that is running in the local container:

    http://localhost:9080/PlantsByWebSphere
 
     ![PBW](./images/media/image61.png)
 
    
    Attempt to click on any of the tabs: “**Flowers**”, **Fruits & Vegetables**”, or “**Trees**”.

    This time it should work without any issue.

8. Finally stop the container

        podman stop pbw-app


    ___

**Considerations & recommendations:**

Another option here instead of setting environment variables is to update the **server.xml** file, add in the sensitive data values that Application Modernization Accelerator did not collect and rebuild the image. 
    
However, a big part of container image value is that they are **`immutable`**. No matter where you take and deploy the image the operating system, runtime, security patch level, etc. will be the same. 
    
This gives you great **reproducibility** and gets away from the classic ‘**but it works for me!**’ issue. We lose much of this value if we bake in the configuration with the image, as we will have to produce an image for each new configuration. 
    
Instead of using the exact same image in each of your development, staging and production environments, you would be using different images. 

___
   
**It is never best practice to hard code configuration into your image.** 


In the next section we will look at how the `migration plan` helps you manage this configuration easily across all your environments and how it will simplify deployment to your OpenShift cluster. The migration plan uses `Kustomize` to help achieve this.

___


## 3.2 Understand how Kustomize is used in the migration plan

**`kustomize`** is simple way to manage configuration across all your different deployments and environments without the need for templates.

By using **`overlays`**, it allows you to break out your basic configuration information (ports, names, hosts, etc.) from your sensitive data (usernames, password, etc.) that are likely to change in every deployment.

Every **kustomize** artifact is plain `YAML` and can be validated and processed in a standardized way. Plus, it makes them very human readable\! It is natively built into **kubectl** and the **OpenShift client**.

Take a look at the kustomize folder structure in the migration plan:

    tree ~/Student/migrationPlan/deploy/kustomize/

  > ![](./images/media/kustomize.png)
 

The structure of the kustomize folder is as follows.

  1.	`base` contains your expected standard deployment in a `config map` (because it is not sensitive data). It also contains the `application.cr-yaml` file that will execute the deployment and mount the necessary secrets that are created from the secret file.

  2.	`overlays` contains all your different deployment configurations. In this case, only a single deployment has been created for your `dev` systems. The `secret` file will contain all your application-specific **sensitive data** that will be created as secrets in OpenShift.

___

**Note:** In the next section we will use this kustomize structure to deploy your application image. 

Further information on **kustomize** can be found at <http://kustomize.io>
    
___


## 4 Deploy to OpenShift with config

You have now created a container image without any application specific configuration. In this section, we will **push** that image to an image repository and then **deploy** it into OpenShift, along with its configuration, with a single command.

### 4.1 Update the Kustomize structure to move the configmap configuration to the overlays folder

It is common to have different application configuration between deployments such as `dev` and `staging`. In this lab, we use only use one different DB2 application databases between the two configurations. For this reason , we want the configMap to be located in the Kustomize `overlays` folder, rather than the `base` where it is placed, by default, in the Application Modernization Accelerator migration plan. 

For the lab, we have provided the updated file structure for you. You just need to run the commands below to update the migration plan. 

1. Move the configMap to the Kustomize `overlays` folder

        cd ~/Student/migrationPlan/deploy/kustomize
        mv base/plantsbywebsphereee6-configmap.yaml overlays/dev/plantsbywebsphereee6-configmap.yaml

2. Remove the reference to plantsbywebsphereee6-configmap.yaml from base/kustomization.yaml

    a. Edit the file and remove the reference

        cd ~/Student/migrationPlan/deploy/kustomize
        gedit base/kustomization.yaml

    > ![](./images/media/configmap_unchanged.png)

    b. Use the following command to review the final file:

        cat base/kustomization.yaml

    c. The content of the file should now look like this:

        # Generated by IBM Migration Artifacts Bundler
        # Thu Oct 22 17:56:54 UTC 2026
        commonLabels:
          app: plantsbywebsphereee6
        resources:
          - application-cr.yaml

3. Add the reference to plantsbywebsphereee6-configmap.yaml to overlays/dev/kustomization.yaml

    a. Edit the file:

        gedit overlays/dev/kustomization.yaml

    b. Add under ressources the following line:

       - plantsbywebsphereee6-configmap.yaml

    
    c. Use the following command to review the final file:

        cat overlays/dev/kustomization.yaml

    d. The content of the file should now look like this:

        # Generated by IBM Migration Artifacts Bundler
        # Thu Oct 22 17:56:54 UTC 2026
        resources:
          - plantsbywebsphereee6-secret.yaml
          - plantsbywebsphereee6-configmap.yaml
        bases:
          - ../../base



### 4.2 Update the YAML files to add the application configuraton for deployment

Recall, the container image does not have the application configuration baked in. 

You will make the following updates to the configuration YAML files in the migration plan for the PlantsByWebSphere application deployment to OpenShift. 

  -  Update the `base/application-cr.yaml` file
     - Add the reference to the container image
     - Accept the Liberty license
  
  -  Update the `overays/dev/plantsbywebsphereee6-secret.yaml` file
     -  Add the sensitive-data to the **secret** YAML file
  
  - Update the `overlays/dev/plantsbywebsphereee6-configmap.yaml` file
     -  Add the database host imformation to access the dev database


1.  Update the `application-cr.yaml` file
    
    The `application-cr.yaml` is the WebSphere Liberty custom resource used to deploy the PlantsByWebSphere application.
  

    a. Adjust the applicationImage IMAGE_REFERENCE" to 
    **default-route-openshift-image-registry.apps.itz-e1vpbd.infra01-lb.dal14.techzone.ibm.com/apps-pbw/pbw-app:1.0**

        sed -i 's/applicationImage: IMAGE_REFERENCE/applicationImage: default-route-openshift-image-registry.apps.itz-e1vpbd.infra01-lb.dal14.techzone.ibm.com\/apps-pbw\/pbw-app:1.0/g' base/application-cr.yaml

    b. Accept the license by replacing "accept: false" with "accept: true"

        sed -i 's/accept: false/accept: true/g' base/application-cr.yaml

    c. Review the updated **application-cr.yaml**
        
        cat ~/Student/migrationPlan/deploy/kustomize/base/application-cr.yaml

    The output should look like this:

    ![](./images/media/application-cr-yaml-pbw.png)

    If you run into any trouble, you can copy the content from below.

        # Generated by IBM Migration Artifacts Bundler
        # Thu Oct 22 17:56:54 UTC 2026
        kind: WebSphereLibertyApplication
        apiVersion: liberty.websphere.ibm.com/v1
        metadata:
            name: plantsbywebsphereee6
        spec:
            replicas: 1
            applicationImage: default-route-openshift-image-registry.apps.itz-e1vpbd.infra01-lb.dal14.techzone.ibm.com/apps-pbw/pbw-app:1.0
            expose: true
            volumeMounts:
            - mountPath: /config/variables
                name: plantsbywebsphereee6-secret
                readOnly: true
            volumes:
                - name: plantsbywebsphereee6-secret
                secret:
                    secretName: plantsbywebsphereee6-secret
            envFrom:
                - configMapRef:
                    name: plantsbywebsphereee6-config
            service:
                port: 9443
            manageTLS: true
            license:
                accept: true


    The updated `application-cr.yaml` in the **base** directory is now complete. The PlantsByWebSphere application configuration is finalized.  

    ___


2.	Update the **plantsbywebsphereee6-secret.yaml** file, which contains the sensitive-data for the application. 

    Adjust the line

    - from: Dmgr01Node_DB2INST1_user: <REPLACE_WITH_BASE64_ENCODED_DATA>
    - to: Dmgr01Node_DB2INST1_user: ZGIyaW5zdDE=

    Use the following command to do so:

        sed -i 's/Dmgr01Node_DB2INST1_user: <REPLACE_WITH_BASE64_ENCODED_DATA>/Dmgr01Node_DB2INST1_user: ZGIyaW5zdDE=/g' overlays/dev/plantsbywebsphereee6-secret.yaml

    Adjust the line

    - from: Dmgr01Node_DB2INST1_password: <REPLACE_WITH_BASE64_ENCODED_DATA>
    - to: Dmgr01Node_DB2INST1_password: ZGIycGFzc3dvcmQ=

    Use the following command to do so:

        sed -i 's/Dmgr01Node_DB2INST1_password: <REPLACE_WITH_BASE64_ENCODED_DATA>/Dmgr01Node_DB2INST1_password: ZGIycGFzc3dvcmQ=/g' overlays/dev/plantsbywebsphereee6-secret.yaml

    Adjust the line

    - from: WIMUserRegistry_1_Default01Cell_userRegistry_primaryAdminId: <REPLACE_WITH_BASE64_ENCODED_DATA>
    - to: WIMUserRegistry_1_Default01Cell_userRegistry_primaryAdminId: d2FzYWRtaW4=>

    Use the following command to do so:

        sed -i 's/WIMUserRegistry_1_Default01Cell_userRegistry_primaryAdminId: <REPLACE_WITH_BASE64_ENCODED_DATA>/WIMUserRegistry_1_Default01Cell_userRegistry_primaryAdminId: d2FzYWRtaW4=/g' overlays/dev/plantsbywebsphereee6-secret.yaml

    Review the final file:

        cat overlays/dev/plantsbywebsphereee6-secret.yaml

    The output should look like this:

    ![](./images/media/secret-yaml-pbw.png)

    If you run into any trouble, you can copy the content from below.

        # Generated by IBM Migration Artifacts Bundler
        # Thu Oct 22 17:56:54 UTC 2026
        kind: Secret
        apiVersion: v1
        metadata:
            name: plantsbywebsphereee6-secret
        type: Opaque
        data:
            Dmgr01Node_DB2INST1_password: ZGIycGFzc3dvcmQ=
            Dmgr01Node_DB2INST1_user: ZGIyaW5zdDE=
            WIMUserRegistry_1_Default01Cell_userRegistry_primaryAdminId: d2FzYWRtaW4=
  
      The update to the `plantsbywebsphereee6-secret.yaml` in the **overlays/dev** directory is now complete. The sensitive data is encoded and added to the yaml file. 


    a. `How did we encode the values?` 
    
    We updated the values in the YAML file with the sensitive data by  **Base64 encoding** the values as illustrated below.
 
    - We encoded the following values:
   
      ___

      - user: **db2inst1**

        echo db2inst1 | base64

      The encoded value is: **ZGIyaW5zdDE=**

      ___

      - password: **db2password**

        echo -n "db2password" | base64

      The encoded value is: **ZGIycGFzc3dvcmQ=**

      ___ 

      - user: **wasadmin**

        echo -n "wasadmin" | base64

      The encoded value is: **d2FzYWRtaW4=**




3.	Update the **plantsbywebsphereee6-configmap.yaml** file, which contains the database name and host for the `dev` database

    Adjust the database endpoint from vm-1 to desktop-2

    Use the following command to do so:

        cd ~/Student/migrationPlan/deploy/kustomize
        sed -i 's/vm-1/desktop-2/g' overlays/dev/plantsbywebsphereee6-configmap.yaml

    Review the final file:

        cat overlays/dev/plantsbywebsphereee6-configmap.yaml

    The output should look like this:

    ![](./images/media/pbw-configmap-yaml-update.png)

    
    The update to the `plantsbywebsphereee6-configmap.yaml` in the **overlays/dev** directory is now complete. The database host for the dev database has been added to the yaml file. 

Review the final configuration:

        cat overlays/dev/plantsbywebsphereee6-configmap.yaml

The output should look like this:

![](./images/media/updated-kustomize-structure.png)

 ### 4.3 Deploy the application and its configuration to OpenShift

To deploy the PlantsByWebSphere application to OpenShift, you must perform the following basic steps.

  - Tag the container image, appropriately tagging for the OpenShift internal registry
 
  - Push the tagged container image to the OpenShift internal registry   

  - Use a single command to deploy and configure the application to openShift


1. Login to OpenShift using your IBM ID 

        oc login -w

2. Create a new project where you will dpeloy the application 

        oc new-project apps-pbw


3. Login to the OpnShift internal registry so you can push the image 

        oc registry login

    The command will return the registry public hostname which should be 
    default-route-openshift-image-registry.apps.itz-e1vpbd.infra01-lb.dal14.techzone.ibm.com

4. Tag the container image using the following podman command

        podman tag apps/pbw default-route-openshift-image-registry.apps.itz-e1vpbd.infra01-lb.dal14.techzone.ibm.com/apps-pbw/pbw-app:1.0

5. Verify the image was tagged

        podman images | grep pbw-app

    ![](./images/media/pbw-apps-tagged.png)


6. Push the container image to OpenShift internal registry 

       podman push default-route-openshift-image-registry.apps.itz-e1vpbd.infra01-lb.dal14.techzone.ibm.com/apps-pbw/pbw-app:1.0         


In previous steps, you configured the sensitive data that is needed, accepted the license, pointed to the image that is needed to pull,  and logged into OpenShift. Now, with a single command, you can deploy to OpenShift and configure the image. 

You must specify which overlay will provide the configuration (dev in this case).

7. Deploy the PlantsByWebSphere application to OpenShift    

        cd ~/Student/labs/appmod/migration-plan/deploy/kustomize

        oc apply -n apps-pbw -k overlays/dev

    The output should show:
    
    configmap/plantsbywebsphereee6-config created
    secret/plantsbywebsphereee6-secret created
    webspherelibertyapplication.liberty.websphere.ibm.com/plantsbywebsphereee6 created


    Ignore warnings like
    - #Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
    - #Warning: 'commonLabels' is deprecated. Please use 'labels' instead. Run 'kustomize edit fix' to update your Kustomization automatically.




8. Verify the deployment

        oc get deployment -n apps-pbw

    Wait for the `deployment` to be ready and availabe, as illustrated below:

        NAME                   READY   UP-TO-DATE   AVAILABLE  
        plantsbywebsphereee6   1/1     1            1    


9. Verify the appliation `pod` is ready.

    This may take a few moments. Just keep checking with command below

        oc get pods -n apps-pbw

    Wait for the `pod` to be ready and availabe, as illustrated below:

        NAME                                    READY   STATUS       
        plantsbywebsphereee6-7476449666-shnx8   1/1     Running   

10. From the browser, navigate to the PlantsByWebSphere route for the `dev` deployment:

      https://plantsbywebsphereee6-apps-pbw.apps.itz-e1vpbd.infra01-lb.dal14.techzone.ibm.com/PlantsByWebSphere
 
    The PlantsByWebSphere main page is displayed.

    ![A website page of a garden Description automatically generated](./images/media/image78a.png)

11. Click on the **`Trees`** category and view the trees that are loaded in the ‘dev’ database.

    This catalog of trees was retrieved from the DB2 database in the `dev` configuration.
 
    ![screenshot](./images/media/image79.png)



##  4.4 Explore the WebSphere Liberty Operator in OpenShift

In this section, you will take a look at the **WebSphere Liberty Operator** in the OpenShift console to see what has been deployed.

1.  Login to OpenShift console

    a.  Open a new tab in the web browser

    b.  Click on the **`OpenShift Console`** bookmark on the bookmark toolbar

    ![OCP Console Login](./images/media/OCP-Console-Login.png)
    
    c.  Log in using your **IBMid**

    d. After successful login, you should land on the overview page

    ![OCP-Console_Overview](./images/media/OCP-Console_Overview.png)
    



2.  View the **IBM WebSphere Liberty** `Operator`

    a.  Click on **`Ecosysytem > Installed Operators`** in the left-hand menu

    ![OCP-Console_Liberty-Operator.png](./images/media/OCP-Console_Liberty-Operator.png)

    b.  Click on **`IBM WebSphere Liberty`**

    ![OCP-Console_Liberty-Operator2.png](./images/media/OCP-Console_Liberty-Operator2.png)



3. View the **WebSphereLibertyApplication** `Deployment`

    a.  Click on the tab called **`WebSphereLibertyApplication`**

    ![OCP-Console_Liberty-Operator3.png](./images/media/OCP-Console_Liberty-Operator3.png)


    b. You will see the **plantsbywebsphereee6** application listed in the ‘dev’ namespace

    ![OCP-Console_Liberty-Application.png](./images/media/OCP-Console_Liberty-Application.png)

    
    b. Click on the link called **`plantsbywebsphereee6`** under the **Name** column

    ![OCP-Console_Liberty-Application2.png](./images/media/OCP-Console_Liberty-Application2.png)

    c.  Select the **`Resources`** tab

    ![OCP-Console_Liberty-Application-PBW.png](./images/media/OCP-Console_Liberty-Application-PBW.png)

    d. Select the link for the **`Deployment`**

    ![OCP-Console_Liberty-Application-PBW2.png](./images/media/OCP-Console_Liberty-Application-PBW2.png)


    e. The PlantsByWebSphere deployment has one `pod` running

    ![OCP-Console_Liberty-Application-PBW3.png](./images/media/OCP-Console_Liberty-Application-PBW3.png)


4.  View the WebSphereLibertyApplication **`Route`**

    a.  Return to the **plantsbywebsphereee6 operator** page

    ![OCP-Console_Liberty-Application-PBW4.png](./images/media/OCP-Console_Liberty-Application-PBW4.png)


    b.  Click the **`Resources`** tab

    ![OCP-Console_Liberty-Application-PBW5.png](./images/media/OCP-Console_Liberty-Application-PBW5.png)


    c.  Select the link of **Kind: `route`**

    ![OCP-Console_Liberty-Application-PBW6.png](./images/media/OCP-Console_Liberty-Application-PBW6.png)


    d.  Click on the **`Location`** link for the route

       https://plantsbywebsphereee6-apps-pbw.apps.itz-e1vpbd.infra01-lb.dal14.techzone.ibm.com/ 

    ![OCP-Console_Liberty-Application-PBW7.png](./images/media/OCP-Console_Liberty-Application-PBW7.png)


    e.  The **Welcome to Liberty** page is displayed in a new Browser tab. 

    ![screenshot](./images/media/image95.png)

    f.  Append the context root ‘**PlantsByWebSphere’** to access the PlantsByWebSphere application

      https://plantsbywebsphereee6-apps-pbw.apps.itz-e1vpbd.infra01-lb.dal14.techzone.ibm.com/PlantsByWebSphere


## 4.5 Re-deploy app with different configuration to OpenShift  - To be done

We have deployed the PlantsByWebSphere application with its configuration to `dev`, using a single kustomize command. 

In this section, we will explain how to deploy the same application again with a new configuration for `staging`, again using a single kustomize command. But as there is no second database deployed, this is a read-only task.


1.	Create a new `overlay` directory called **staging** that will store the new staging configuration, coping the existing dev directory.

        cd ~/Student/labs/appmod/migration-plan/deploy/kustomize/overlays

        cp -r dev staging

2.	Update the **plantsbywebsphereee6-configmap.yaml** file, which contains the database name and host for the **staging** configuration.

    As there is no staging database deployed, there is nothing to change here.
 
3. From the `kustomize` directory, apply the new `staging` overlay

        cd ~/Student/labs/appmod/migration-plan/deploy/kustomize

        oc apply -n apps-pbw -k overlays/staging

    **Note:** that the configmap and secret were `configured`,  but the application is `unchanged`, as illustrated below.  

4. Ensure the pod has restarted

        oc get pods -n apps-pbw


5. From the browser, navigate to the PlantsByWebSphere route for the application

 
 
# Summary

___
**Congratulations!**

**You have successfully completed the core learning objectives in the lab**

___

In this lab, you learned how to deploy applications to WebSphere Liberty using the WebSphere Liberty Operator and the deployment artifacts produced by Application Modernization Accelerator in its migration plan.

You explored the options for deployment: 

  - locally running Liberty
  - Liberty as an image running in local container
  - Liberty as an image running in OpenShift.

You learned how to easily configure deployments to OpenShift to allow the same immutable image to be deployed for different configurations such as ‘dev’ and ‘staging’ environment deployments.

You learned about some of the practical ways you can secure your configuration data.

You explored the PlantsByWebSphere assessment details and reports in Application Modernization Accelerator.


___

You may continue your learning journey with the optional sections of the lab. 

___


# Optional Sections: 

<details>
 <summary><b><font color="dodgerblue">Click to expand:</font></b> Section 5: (Optional) GitOps and configuration management
 </summary>

<br/>

## 5 GitOps and configuration management

At this point we have two distinct elements for deployment: the **application image** and the **configuration for that image for each potential environment**. In the GitOps model, these two elements are stored in separate Git repositories. 

You can further distribute the configuration into different repositories for each environment. This approach allows you to treat configuration as if it were code and to apply standard code development techniques such as Pull Requests, code review and maintain a full audit history. This approach delivers excellent controls and oversights for configuration changes for your OpenShift clusters, especially as you promote changes through your environments.

![A black background with white arrows and dots Description automatically generated](./images/media/image105.png)

We will not cover all of GitOps it in detail in this lab - however, there are two relevant areas that are worth mentioning briefly.

**Configuration Drift**

With the GitOps approach, there is the risk that the deployed configuration for the OpenShift cluster does not match what is in the Git repository. Someone could have updated the OpenShift cluster directly, for example. There are a number of tools to manage this configuration drift, with ArgoCD being a common tool to address this issue. It can be configured to sync manually or automatically, so that any changes made directly on the cluster are reverted to what is in the Git repository. 

The OpenShift GitOps Operator can be used to install ArgoCD into your OpenShift cluster. 

**Securing Secrets**

Even with controls and restricted access to Git repositories, it is not considered good practice to store the sensitive data in plain text (aka the values entered into the secrets files). 
There are generally two approaches you can take to tackle this, encrypt the values or use a reference:

  - **Encrypt the values**: In this approach, the value in the secret file is encrypted when it is committed to the Git repo. During deployment to OpenShift there is an extra step where the secret values are decrypted. `SealedSecrets` is one implementation of such an approach.

  - **Use a reference**: In this case, the secrets and their values are stored in a secret manager. During deployment, a reference is provided to the secret manager which will then mount the secret to the deployed container. `HashiCorp Vault` is a common implementation of this approach.

In both cases, there is additional work to be done above what has been covered in this lab. However, the kustomize files provided in the migration plan gives you a good starting point to identify the secrets and provide a standard output that can be transformed to suit your selected approach.

</details>


<details>
 <summary><b><font color="dodgerblue">Click to expand:</font></b> Section 6: (Optional) Exploring the PlantsByWebSphere application in the proof_of_concept workspace
 </summary>

<br/>

## 6 Exploring the PlantsByWebSphere application in the proof_of_concept workspace

IBM Cloud Application Modernization Accelerator (TA) analyzes application and configuration data collected from Java application server environments. TA delivers great insights that help organizations plan and implement a modernization journey to WebSphere Liberty and Kubernetes base container platform for existing Java applications.
 
TA provides recommendations for modernization which includes and considers application complexity, dependencies, potential issues, and estimated development effort.
 
![screenshot](./images/media/image106.png)

1. In a browser window, return to Application Modernization Accelerator using the following URL: 

        http://localhost:3000

2. Open the `proof_of_concept` workspace, if it is not already open

    ![](./images/media/ta-proof-of-concept.png)


3.  Scroll down to the `Java applications` section and note the high-level summary for the ‘**plantsbywebsphereee6.ear**’application assessment.

  - Complexity

  - Issues

  - Required code changes

  - Application cost (in days for development)

    ![](./images/media/image107.png)

This workspace has only a single application name `plantsbywebsphereee6.ear`. It is summarized as `simple` to  modernize to WebSphere Liberty.  

 ***Complexity values and their meanings:***
 
**`Simple`**: The application is ready for deployment, no access to the source code is required. 

  - Simple complexity value typically represents about 20% of applications.
 
 **`Moderate`**: Code changes are required before deployment; however, these code changes are well known, and specific help is provided for each issue to assist in resolving it. 
 
   - Moderate complexity value typically represents about 80% of applications.
 
 **`Complex`**: The application uses a technology that does not have a direct equivalent in the new runtime and a new approach will need to be adopted. In our experience, only about 1 in 6 customers have these kinds of applications. 
 
   - Complex complexity value typically represents less than 1% of applications.

4. Click on **plantsByWebSphereee6.ear** which will expand the analysis

    ![screenshot](./images/media/image108.png)

    a. Scroll down, noting the groups or categories of analysis available
    
    - **Complexity rules**
    
    - **Required code changes**
    
    - **Issue details**

      - Critical

      - Warning

      - Informational
    
    - **Additional reports**

      - Technology report

      - Inventory report

      - Analysis reports


5.  View the **`Analysis Report`** for more detailed application information

    **Analysis Report**

    The **Detailed Migration Analysis Report** does a deep dive on the preferred migration target to help you understand any migration issues, like deprecated or removed APIs, Java SE version differences, and Java EE behavioral differences.

    a.  Click on the **`Analysis report`** link. 

    ![screenshot](./images/media/image109.png)

    b. The **Analysis report** will open in a new browser tab

    ![screenshot](./images/media/image110.png)
 

    c.  Note the **target**

    - Because the **source** was traditional WebSphere v8.5.5, which is Java EE 6, the target is also EE6.

    - Because the source was running Jave SE 8, the target is also set to Java SE 8.

    By default, Application Modernization Accelerator recommends the first step of modernization to Liberty that requires the minimal amount of change and effort.
 
    You may use the binary scanner with the `--ta` option if you want to assess the modernization effort to newer versions Java, Jave EE, or Jakarta EE. Running the binary scanner with the `-ta` option produces an archive file that can be loaded into Application Modernization Accelerator for analysis.

    d.  Click on the **`Information`** label, to review the details of this item.

    ![screenshot](./images/media/image112.png)
 
    The **Information** rules provide migration related considerations. Be aware of these rules during testing. Many of these rules relate to connectivity to other resources that need to be considered during migration.

    e.  You may review the Information rules for PlantsByWebSphere migration.

    ![screenshot](./images/media/image113.png)


6.  Return to the **Cloud Application Modernization Accelerator** browser tab that shows the **plantsbywebsphereee6.ear details** page. Then click on **`Inventory Report`**, which will open in a new browser tab.

    ![screenshot](./images/media/image114.png)

    a.  Scroll down and review the Inventory Report, which is especially useful in larger applications.

    The **Inventory report** provides a high-level inventory of the content and structure of each application, plus information about potential deployment problems and performance considerations.
 
    ![](./images/media/image115.png)

    b.  Scroll down to the bottom of the **Inventory report** and locate the **`Contained Archives`** section.

    The inventory report provides valuable insights into utility jars that are contained in the application. It also provides the ‘package’ name of the utility jar. This is extremely valuable to help determine what 3<sup>rd</sup> party utilities are used by the application.

    c.  Notice the PlantsByWebSphere application contains utility jar named **‘pbw-lib’jar**’. The archive package is “ibm.com.websphere’, indicating it is NOT a 3<sup>rd</sup> party utility jar.

    ![screenshot](./images/media/image116.png)

    d.  Return to the **Cloud Application Modernization Accelerator** browser tab that shows the **plantsbywebsphereee6.ear details** page. Then click on **`Technology report`**, which will open in a new browser tab.

    The **Technology report** provides details on which editions of Liberty support the technologies used by the applications.
 
    ![screenshot](./images/media/image117.png)

    a.  Scroll down the Technology Report, which can quickly help assess which Java EE API technologies that the PlantsByWebSphere application uses, and which editions of Liberty the APIs are available.

    ![screenshot](./images/media/image118.png)

    b. As you see from the report above, the APIs used in the PlantsByWebSphere application are available in ALL editions of Liberty.

</details>


