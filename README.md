# Designing-and-Developing-a-High-Availability-Hybrid-Cloud-Architecture

## 🎯 Project Overview
This graduation project demonstrates a **high-availability hybrid-cloud architecture** integrating web, database, DNS, and load balancer servers. The infrastructure is provisioned automatically using **Vagrant**, **VirtualBox**, and **Linux shell scripts** to simulate a production-like environment.


The project aims to showcase:
- Fault tolerance
- Scalability
- Automated provisioning
- Hybrid cloud deployment

## 🖥️ Components

| Component        | Description |
|-----------------|-------------|
| **Web Servers**   | Multi-instance Python Flask applications running on **Gunicorn**. |
| **Database Server** | **MariaDB** for structured data storage with automated setup. |
| **Load Balancer** | **Nginx** configured for **Layer 4 (SSL Passthrough)** or **Layer 7 (HTTPS termination)** load balancing. |
| **DNS Server**    | **Dnsmasq** providing local domain resolution for internal networking. |

## 🛠️ Prerequisites
- **Windows** OS with **Git Bash**
- **Chocolatey** package manager
- Installed tools:
  ```bash
  choco install virtualbox --version=7.1.4 -y
  choco install vagrant --version=2.4.3 -y
  choco install vscode -y

## Resources
* Vagrant resources/tutorials: [Playlist](https://www.youtube.com/playlist?list=PLQ5OGqigB8Vnwn4RSAxQBz1DEvgBmAT-u)
* linux firewall : [video](https://youtu.be/IldTerjkfA0?si=Fzicto2SxOPVurLt)
* Nginx load balancing resources/tutorials: [Documentation ](https://docs.nginx.com/nginx/admin-guide/load-balancer/http-load-balancer/)
* DNSmasq resources/tutorials: [Playlist]( https://www.youtube.com/playlist?list=PL2Z9mQ8mdWnoeWPgGwV1wNe8du0TQqrao)
  

## ⚡ Setup Instructions

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd <your-project-folder>
   ```

2. **Start the Vagrant environment**

   ```bash
   vagrant up
   ```

3. **Access your web application**

   * Open your browser and navigate to:

     ```
     https://applicationx.domain.com
     ```
   * The **load balancer** distributes traffic across all web servers.

4. **Access each VM for troubleshooting**

   ```bash
   vagrant ssh <machine-name>
   ```

## 📂 Project Structure

```
.
├── Vagrantfile
├── scripts/
│   ├── web.sh        # Web server provisioning script
│   ├── db.sh         # Database server provisioning script
│   ├── lb.sh         # Load balancer script
│   └── dns.sh        # DNS server script
├── README.md         # Project documentation
└── ...
```

## 🔧 Features

* Fully automated provisioning using shell scripts
* Layer 4 and Layer 7 load balancing options
* HTTPS setup with self-signed certificates
* Firewall configuration included
* Supports high-availability simulation in a local environment

## 📌 Notes

* Load balancer configuration can be switched between **Layer 4 (TCP/SSL passthrough)** and **Layer 7 (HTTPS termination)** by editing `lb.sh`.
* Python scripts and Gunicorn are installed in `/usr/local/bin`, ensure your PATH includes this directory if you need direct access.
* Recommended to use **Vagrant snapshots** to save the state of the environment after provisioning.

## 🎓 Author

**Emad Singab** – Graduation Project, Mansoura University, Faculty of Engineering, Communication & Electronics Specialization

```

ممكن أعمل لك كمان نسخة **مختصرة للـ GitHub + LinkedIn** تكون جذابة بصريًا مع **badges** عشان الريبو يبقى portfolio جاهز للعرض. تحب أعملها لك؟
```
