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
   💡 Small Tip:
After running vagrant up, the provisioning process takes around 30 minutes, so feel free to take a break, grab a coffee, and come back once everything is ready ☕😉

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
   Here is a clean, professional **English version** of the README section — formatted exactly for GitHub and suitable for production-level documentation.

---

# ⚙️ Local Environment Setup & Troubleshooting

These steps are required to run the project locally without issues related to **DNS resolution** or **HTTPS certificate validation** during Frontend ⇆ Backend testing.

---

## ✅ 1. Configure Local DNS

The project relies on a **local DNS server** inside the network (e.g., `192.168.100.30`) to resolve internal service names.
Correct DNS configuration ensures proper communication between the frontend, backend, and other components.

### **Steps to configure DNS on Windows:**

1. Open **Command Prompt** and run:

   ```bash
   ipconfig
   ```

   Identify your active **Ethernet Adapter** and check:

   * IPv4 Address 192.168.100.0/24
   * Subnet Mask
   * Default Gateway

2. Open:

   ```
   Control Panel → Network and Internet → Network and Sharing Center
   ```

3. Click:

   ```
   Change adapter settings
   ```

4. Right-click **Ethernet** → select **Properties**

5. Select:

   ```
   Internet Protocol Version 4 (TCP/IPv4)
   ```

   then click **Properties**.

6. Click **Advanced…**

7. Go to the **DNS** tab.

8. Remove any existing DNS servers and add the local DNS:

   ```
   192.168.100.30
   ```

9. Save all changes by clicking **OK**.

---

## ✅ 2. Run Chrome Without Certificate Validation (Local Testing Only)

Since the local environment uses a **self-signed HTTPS certificate**, Chrome may block the site.
For local development only, you can launch Chrome with certificate verification disabled.

### **Steps:**

1. Press:

   ```
   Win + R
   ```

2. Run the following command:

   ```
   chrome.exe --ignore-certificate-errors --user-data-dir=%LOCALAPPDATA%\Google\Chrome\User Data\Default_Test_Profile
   ```

> This launches Chrome with a separate test profile that ignores HTTPS certificate validation for local testing.

---

##  Summary

| Task                                | Purpose                                                  |
| ----------------------------------- | -------------------------------------------------------- |
| Configure Local DNS                 | Allow local hostname resolution through internal DNS     |
| Ignore Certificate Errors in Chrome | Enable local HTTPS testing with self-signed certificates |

---

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

