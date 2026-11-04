\# Vagrant Multi-Tier Java Web Application



A multi-tier Java web application deployed on a local virtualized infrastructure using \*\*Vagrant\*\*, \*\*VirtualBox\*\*, \*\*Nginx\*\*, \*\*Apache Tomcat\*\*, \*\*MariaDB\*\*, \*\*RabbitMQ\*\*, and \*\*Memcached\*\*.



The project demonstrates infrastructure provisioning, service configuration, reverse proxy setup, and communication between multiple application tiers.



\## Architecture



```mermaid

flowchart TD

&#x20;   A\["Client / Web Browser"] --> B\["Nginx - web01"]

&#x20;   B --> C\["Apache Tomcat - app01"]

&#x20;   C --> D\[("MariaDB - db01")]

&#x20;   C --> E\["RabbitMQ - rmq01"]

&#x20;   C --> F\["Memcached - mc01"]

```



\### Infrastructure Overview



The infrastructure consists of five Ubuntu virtual machines:



| VM | Role | IP Address | Service Port | RAM |

|---|---|---|---|---|

| web01 | Web Server / Reverse Proxy | 192.168.56.11 | 80 | 1 GB |

| app01 | Application Server | 192.168.56.12 | 8080 | 2 GB |

| rmq01 | Message Broker | 192.168.56.13 | 5672 | 1 GB |

| mc01 | Caching Server | 192.168.56.14 | 11211 | 1 GB |

| db01 | Database Server | 192.168.56.15 | 3306 | 2 GB |



\*\*Total allocated memory:\*\* 7 GB



\## Technology Stack



\- \*\*Virtualization:\*\* VirtualBox

\- \*\*Infrastructure Provisioning:\*\* Vagrant

\- \*\*Operating System:\*\* Ubuntu 22.04 LTS

\- \*\*Web Server:\*\* Nginx

\- \*\*Application Server:\*\* Apache Tomcat 10.1.26

\- \*\*Programming Runtime:\*\* Java 17

\- \*\*Build Tool:\*\* Apache Maven

\- \*\*Database:\*\* MariaDB

\- \*\*Message Broker:\*\* RabbitMQ

\- \*\*Caching:\*\* Memcached

\- \*\*Automation:\*\* Bash Shell Scripts



\## Project Structure



```text

01-vagrant-multi-tier-java-app/

Ã¢â€â€š

Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ Vagrantfile

Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ config.env.example

Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ .gitignore

Ã¢â€â€š

Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ db\_provision.sh

Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ memcache\_provision.sh

Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ nginx\_provision.sh

Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ rabbitmq\_provision.sh

Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ tomcat\_provision.sh

```



\## Prerequisites



Make sure the following tools are installed on your host machine:



\- \[VirtualBox](https://www.virtualbox.org/)

\- \[Vagrant](https://developer.hashicorp.com/vagrant/install)

\- Git

\- Vagrant Host Manager plugin



Install the Host Manager plugin:



```bash

vagrant plugin install vagrant-hostmanager

```



\## Deployment Guide



\### 1. Clone the Repository



```bash

git clone <YOUR\_REPOSITORY\_URL>

cd 01-vagrant-multi-tier-java-app

```



\### 2. Configure Environment Variables



Create your local configuration file from the example:



\*\*PowerShell:\*\*



```powershell

Copy-Item config.env.example config.env

notepad config.env

```



Update the values with your own credentials:



```env

DB\_NAME=accounts

DB\_USER=admin

DB\_PASS=YOUR\_DB\_PASSWORD



RMQ\_USER=test

RMQ\_PASS=YOUR\_RABBITMQ\_PASSWORD

```



\*\*Important:\*\* Never commit `config.env` or expose real credentials in your repository.



\### 3. Start the Infrastructure



Run:



```bash

vagrant up

```



Vagrant will create the five virtual machines and execute their provisioning scripts.



\### 4. Check VM Status



```bash

vagrant status

```



\### 5. Access the Application



Open your browser and navigate to:



```text

http://192.168.56.11

```



Nginx receives incoming HTTP requests and forwards them to the Tomcat application server.



\## Provisioning Scripts



Each virtual machine has a dedicated provisioning script:



| Script | Responsibility |

|---|---|

| `nginx\_provision.sh` | Installs and configures Nginx as a reverse proxy |

| `tomcat\_provision.sh` | Installs Java, Maven, and Tomcat; builds and deploys the Java application |

| `db\_provision.sh` | Installs MariaDB and configures the application database and user |

| `rabbitmq\_provision.sh` | Installs RabbitMQ and configures its application user |

| `memcache\_provision.sh` | Installs and configures Memcached |



\## Validation and Testing



The following checks were performed during deployment:



\- All five virtual machines started successfully.

\- Required services were installed and running.

\- Network connectivity between the infrastructure components was checked.

\- Application server responded on port `8080`.

\- Nginx reverse proxy successfully forwarded requests to Tomcat.

\- The application was accessible through the Nginx frontend.

\- Application login and dashboard access were tested.



Example HTTP check:



```bash

curl -I http://192.168.56.11

```



Expected response:



```text

HTTP/1.1 200 OK

```



\## Application Source



The Java application is based on the VProfile project:



\[https://github.com/hkhcoder/vprofile-project](https://github.com/hkhcoder/vprofile-project)



The provisioning process clones the `local` branch, configures the application properties, builds the project using Maven, and deploys the generated WAR file to Tomcat.



The application source is retrieved during provisioning and is not included in this repository.



Please refer to the original project's license and attribution requirements.



\## Security Considerations



\- Credentials are stored locally in `config.env`.

\- `config.env` is excluded through `.gitignore`.

\- `config.env.example` contains placeholders only.

\- The RabbitMQ administrator account is intended for this local lab environment.

\- Services are configured for communication over the Vagrant private network.



\*\*This project is intended for learning and demonstration purposes. It is not a production-hardened deployment.\*\* Production environments should use a dedicated secrets-management solution, restricted network access, TLS, least-privilege accounts, and hardened service configurations.



\## Known Limitations



\- Provisioning scripts are designed for initial lab deployment and are not fully idempotent.

\- The Tomcat provisioning script removes and reinstalls the existing Tomcat directory during provisioning.

\- The application build currently skips automated tests using Maven's `-DskipTests` option.



\## Learning Outcomes



Through this project, I practiced:



\- Designing a multi-tier application architecture.

\- Automating VM creation with Vagrant.

\- Configuring Linux services using Bash.

\- Deploying a Java application on Apache Tomcat.

\- Configuring Nginx as a reverse proxy.

\- Setting up database, messaging, and caching services.

\- Managing application configuration and credentials.

\- Troubleshooting connectivity and service-level issues.



\---



**Project Type:** DevOps / Infrastructure Automation

**Environment:** Local Virtualized Lab

\*\*Status:\*\* Deployed and Tested
