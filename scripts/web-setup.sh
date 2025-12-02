#!/bin/bash
echo "--- Provisioning Web Server ($(hostname)) ---"

# =================================================================
#  				1. Install Base System Dependencies
# =================================================================
echo "--> Installing system dependencies..."
sudo dnf module enable mariadb:10.11 -y > /dev/null
sudo dnf install -y pkg-config gcc python3-devel mariadb-devel openssl python3-pip > /dev/null

# =================================================================
#  		2. Install Python Libraries with compatible versions
# =================================================================
echo "--> Installing compatible Python libraries..."
sudo pip3 install --force-reinstall --no-cache-dir Flask==2.2.2 "Flask-MySQLdb==1.0.1" Werkzeug==2.3.8 Flask-Cors gunicorn > /dev/null

# =================================================================
#  		3. Create Project Directory and Application Files
# =================================================================
echo "--> Creating application files..."
mkdir -p /home/vagrant/myproject
cd /home/vagrant/myproject

# Create app.py
cat > app.py << 'EMD'
from flask import Flask, request, jsonify
from flask_mysqldb import MySQL
from flask_cors import CORS
import os
import socket

app = Flask(__name__, static_folder='.')

CORS(app)

app.config['MYSQL_HOST'] = '192.168.100.10'
app.config['MYSQL_USER'] = 'app_user'
app.config['MYSQL_PASSWORD'] = 'cairo123'
app.config['MYSQL_DB'] = 'company_db'
app.config['MYSQL_CURSORCLASS'] = 'DictCursor'

mysql = MySQL(app)

@app.route('/')
def index():
    return app.send_static_file('index.html')

@app.route('/hostname')
def get_hostname():
    try:
        hostname = socket.gethostname()
        return jsonify({'hostname': hostname})
    except Exception as e:
        print(f"Error getting hostname: {e}")
        return jsonify({'hostname': 'Unknown Server'}), 500

@app.route('/api/employees', methods=['GET'])
def get_employees():
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM employees ORDER BY id DESC")
    employees = cur.fetchall()
    cur.close()
    return jsonify(employees)

@app.route('/api/employees', methods=['POST'])
def add_employee():
    data = request.get_json()
    cur = mysql.connection.cursor()
    cur.execute("INSERT INTO employees (name, phone, email, position, salary) VALUES (%s, %s, %s, %s, %s)",
                (data['name'], data['phone'], data['email'], data['position'], data['salary']))
    mysql.connection.commit()
    cur.close()
    return jsonify({'message': 'Employee added'}), 201

@app.route('/api/employees/<int:id>', methods=['PUT'])
def update_employee(id):
    data = request.get_json()
    cur = mysql.connection.cursor()
    cur.execute("UPDATE employees SET name=%s, phone=%s, email=%s, position=%s, salary=%s WHERE id=%s",
                (data['name'], data['phone'], data['email'], data['position'], data['salary'], id))
    mysql.connection.commit()
    cur.close()
    return jsonify({'message': 'Employee updated'})

@app.route('/api/employees/<int:id>', methods=['DELETE'])
def delete_employee(id):
    cur = mysql.connection.cursor()
    cur.execute("DELETE FROM employees WHERE id = %s", [id])
    mysql.connection.commit()
    cur.close()
    return jsonify({'message': 'Employee deleted'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
EMD

# Create index.html
cat > index.html << 'EMD'
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>نظام إدارة الموظفين</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css" rel="stylesheet">
    
    <style>
        /* إعادة تعريف الألوان الأصلية */
        :root {
            --primary-dark-blue: #2c3e50; 
            --primary-teal: #1abc9c;   
            --accent-blue: #3498db;     
            --background-light: #ecf0f1;
            --card-background: #ffffff; 
            --text-dark: #333333;      
            --border-color: #e0e0e0;   
            --table-header-bg: #f2f4f6;
        }

        body { background-color: var(--background-light); color: var(--text-dark); }
        .navbar { background-color: var(--primary-dark-blue); box-shadow: 0 3px 8px rgba(0,0,0,0.15); }
        .navbar .navbar-brand { font-weight: 700; font-size: 1.5rem; }
        .container { max-width: 1100px; margin-top: 40px; margin-bottom: 40px; }
        
        .card { 
            border-radius: 1rem; box-shadow: 0 8px 20px rgba(0,0,0,0.1); border: none;
        }
        
        /* تنسيق جدول الموظفين */
        .table-custom thead th { 
            background-color: var(--table-header-bg); font-weight: 600;
        }
        .table-custom tbody tr:hover { 
            background-color: #eaf2f8; cursor: pointer;
        }

        /* تنسيق زر الإضافة */
        .btn-primary-custom {
            background-color: var(--primary-teal); border-color: var(--primary-teal); color: white;
            font-weight: 600; border-radius: 0.5rem; transition: background-color 0.3s;
        }
        .btn-primary-custom:hover {
            background-color: #16a085; border-color: #16a085; color: white;
        }

        /* بطاقة الإحصائيات */
        .stats-card {
            background-color: var(--card-background); border: 1px solid var(--border-color);
            padding: 20px; text-align: center; border-radius: 1rem; box-shadow: 0 5px 15px rgba(0,0,0,0.08);
        }
        .stats-card h4 {
            color: var(--primary-teal); font-size: 2rem; font-weight: 700;
        }
        
        /* التنبيهات المنبثقة */
        .custom-alert {
            position: fixed; top: 25px; left: 50%; transform: translateX(-50%); z-index: 1060;
            padding: 15px 25px; border-radius: 0.75rem; box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            display: none; max-width: 450px; text-align: center; font-weight: 500;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="#"><i class="fas fa-users me-2"></i>نظام إدارة الموظفين</a>
        </div>
    </nav>

    <div class="container">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="h2" style="color: var(--primary-dark-blue); font-weight: 700;">قائمة الموظفين</h1>
                <p id="server-hostname" class="text-muted small">جاري التحميل...</p>
            </div>
            <button class="btn btn-primary-custom" data-bs-toggle="modal" data-bs-target="#addEmployeeModal">
                <i class="fas fa-plus me-2"></i>إضافة موظف جديد
            </button>
        </div>

        <div class="row mb-5">
            <div class="col-md-12"> 
                <div class="stats-card">
                    <h4><span id="total-employees">0</span></h4>
                    <p class="text-muted">إجمالي الموظفين</p>
                </div>
            </div>
        </div>

        <div class="card shadow-lg">
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-custom table-hover align-middle mb-0">
                        <thead>
                            <tr>
                                <th>الاسم</th>
                                <th>رقم الهاتف</th>
                                <th>البريد الإلكتروني</th>
                                <th>الوظيفة</th>
                                <th>الراتب</th>
                                <th class="text-center">إجراءات</th>
                            </tr>
                        </thead>
                        <tbody id="employee-list"></tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="addEmployeeModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header bg-success text-white">
                    <h5 class="modal-title">إضافة موظف جديد</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="add-employee-form">
                        <div class="mb-3"><input type="text" class="form-control" id="add-name" placeholder="الاسم" required></div>
                        <div class="mb-3"><input type="text" class="form-control" id="add-phone" placeholder="رقم الهاتف"></div>
                        <div class="mb-3"><input type="email" class="form-control" id="add-email" placeholder="البريد الإلكتروني"></div>
                        <div class="mb-3"><input type="text" class="form-control" id="add-position" placeholder="الوظيفة"></div>
                        <div class="mb-3"><input type="number" class="form-control" id="add-salary" placeholder="الراتب"></div>
                        <button type="submit" class="btn btn-success w-100"><i class="fas fa-save me-2"></i>إضافة</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="editEmployeeModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header bg-primary text-white">
                    <h5 class="modal-title">تعديل بيانات الموظف</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="edit-employee-form">
                        <input type="hidden" id="edit-id">
                        <div class="mb-3"><input type="text" class="form-control" id="edit-name" required placeholder="الاسم"></div>
                        <div class="mb-3"><input type="text" class="form-control" id="edit-phone" placeholder="رقم الهاتف"></div>
                        <div class="mb-3"><input type="email" class="form-control" id="edit-email" placeholder="البريد الإلكتروني"></div>
                        <div class="mb-3"><input type="text" class="form-control" id="edit-position" placeholder="الوظيفة"></div>
                        <div class="mb-3"><input type="number" class="form-control" id="edit-salary" placeholder="الراتب"></div>
                        <button type="submit" class="btn btn-primary w-100"><i class="fas fa-check-circle me-2"></i>حفظ التعديلات</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <div id="custom-alert-message" class="custom-alert alert" role="alert"></div>

    <div class="modal fade" id="confirmDeleteModal" tabindex="-1">
        <div class="modal-dialog modal-sm">
            <div class="modal-content">
                <div class="modal-header bg-danger text-white">
                    <h5 class="modal-title">تأكيد الحذف</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body text-center">
                    <i class="fas fa-exclamation-triangle text-danger mb-3 fa-2x"></i><br>
                    هل أنت متأكد من رغبتك في حذف هذا الموظف؟
                </div>
                <div class="modal-footer justify-content-center">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">إلغاء</button>
                    <button type="button" class="btn btn-danger" id="confirm-delete-btn">حذف</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        $(document).ready(function() {
            const baseUrl = window.location.protocol + '//' + window.location.host;
            const apiUrl = `${baseUrl}/api/employees`;

            // دالة الإشعارات (استخدام فئات Bootstrap لتحديد الألوان)
            function showAlert(message, type = 'info', duration = 3000) {
                const alertBox = $('#custom-alert-message');
                // يتم تعيين ألوان التنبيهات من فئات Bootstrap: success, danger, info
                alertBox.removeClass().addClass(`custom-alert alert alert-${type}`);
                alertBox.text(message).fadeIn();
                setTimeout(() => {
                    alertBox.fadeOut();
                }, duration);
            }

            // جلب اسم الخادم
            $.ajax({
                url: `${baseUrl}/hostname`, type: 'GET',
                success: function(data) {
                    $('#server-hostname').text('الخادم: ' + (data.hostname || 'Local Server'));
                },
                error: function() {
                    $('#server-hostname').text('الخادم: غير معروف');
                }
            });

            // جلب وعرض بيانات الموظفين (باقي وظائف JavaScript لم تتغير)
            function fetchEmployees() {
                $.get(apiUrl)
                .done(function(data) {
                    $('#employee-list').empty();
                    $('#total-employees').text(data.length); 

                    if (data.length === 0) {
                        $('#employee-list').append('<tr><td colspan="6" class="text-center py-4 text-muted">لا توجد بيانات موظفين حاليًا.</td></tr>');
                    } else {
                        data.forEach(emp => {
                            $('#employee-list').append(`
                                <tr>
                                    <td>${emp.name}</td>
                                    <td>${emp.phone || '-'}</td>
                                    <td>${emp.email || '-'}</td>
                                    <td>${emp.position || '-'}</td>
                                    <td>${emp.salary || '-'}</td>
                                    <td class="text-center">
                                        <button class="btn btn-sm btn-info edit-btn me-1" data-id="${emp.id}" data-bs-toggle="modal" data-bs-target="#editEmployeeModal" title="تعديل"><i class="fas fa-edit"></i></button>
                                        <button class="btn btn-sm btn-danger delete-btn" data-id="${emp.id}" title="حذف"><i class="fas fa-trash-alt"></i></button>
                                    </td>
                                </tr>
                            `);
                        });
                    }
                })
                .fail(function() {
                    showAlert("فشل في جلب بيانات الموظفين. تحقق من الاتصال.", "danger");
                });
            }

            // منطق إضافة موظف جديد (لم يتغير)
            $('#add-employee-form').submit(function(e) {
                e.preventDefault();
                const newEmployee = { name: $('#add-name').val(), phone: $('#add-phone').val(), email: $('#add-email').val(), position: $('#add-position').val(), salary: $('#add-salary').val() };
                $.ajax({
                    url: apiUrl, type: 'POST', contentType: 'application/json', data: JSON.stringify(newEmployee),
                    success: function() {
                        fetchEmployees();
                        $('#addEmployeeModal').modal('hide');
                        $('#add-employee-form')[0].reset();
                        showAlert("تمت إضافة الموظف بنجاح.", "success");
                    },
                    error: function() {
                        showAlert("فشل في إضافة الموظف.", "danger");
                    }
                });
            });

            // منطق الحذف والتعديل (لم يتغير)
            let employeeToDeleteId = null;
            $('#employee-list').on('click', '.delete-btn', function() {
                employeeToDeleteId = $(this).data('id');
                const confirmModal = new bootstrap.Modal(document.getElementById('confirmDeleteModal'));
                confirmModal.show();
            });

            $('#confirm-delete-btn').on('click', function() {
                const id = employeeToDeleteId;
                if (id) {
                    $.ajax({
                        url: `${apiUrl}/${id}`, type: 'DELETE',
                        success: function() {
                            fetchEmployees();
                            showAlert("تم حذف الموظف بنجاح.", "success");
                            $('#confirmDeleteModal').modal('hide');
                        },
                        error: function() {
                            showAlert("فشل في حذف الموظف.", "danger");
                            $('#confirmDeleteModal').modal('hide');
                        }
                    });
                }
            });

            $('#employee-list').on('click', '.edit-btn', function() {
                const row = $(this).closest('tr');
                const id = $(this).data('id');
                $('#edit-id').val(id);
                $('#edit-name').val(row.find('td:eq(0)').text());
                $('#edit-phone').val(row.find('td:eq(1)').text() === '-' ? '' : row.find('td:eq(1)').text());
                $('#edit-email').val(row.find('td:eq(2)').text() === '-' ? '' : row.find('td:eq(2)').text());
                $('#edit-position').val(row.find('td:eq(3)').text() === '-' ? '' : row.find('td:eq(3)').text());
                $('#edit-salary').val(row.find('td:eq(4)').text() === '-' ? '' : row.find('td:eq(4)').text());
            });

            $('#edit-employee-form').submit(function(e){
                e.preventDefault();
                const id = $('#edit-id').val();
                const updatedEmployee = { name: $('#edit-name').val(), phone: $('#edit-phone').val(), email: $('#edit-email').val(), position: $('#edit-position').val(), salary: $('#edit-salary').val() };
                $.ajax({
                    url: `${apiUrl}/${id}`, type: 'PUT', contentType: 'application/json', data: JSON.stringify(updatedEmployee),
                    success: function() {
                        fetchEmployees();
                        $('#editEmployeeModal').modal('hide');
                        showAlert("تم تحديث بيانات الموظف بنجاح.", "success");
                    },
                    error: function() {
                        showAlert("فشل في تحديث بيانات الموظف.", "danger");
                    }
                });
            });

            fetchEmployees();
        });
    </script>
</body>
</html>
EMD

# =================================================================
# 		4. Create HTTPS Certificate and Set Permissions
# =================================================================
echo "--> Creating SSL certificate and setting permissions..."
sudo mkdir -p /etc/ssl/private
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/CN=applicationx.domain.com"
sudo chgrp vagrant /etc/ssl/private/nginx-selfsigned.key
sudo chmod 640 /etc/ssl/private/nginx-selfsigned.key

# =================================================================
# 			5. Create systemd service file for Gunicorn
# =================================================================
echo "--> Creating and enabling gunicorn systemd service..."
cat > /etc/systemd/system/gunicorn.service << 'EMD'
[Unit]
Description=Gunicorn instance to serve Employee Management app
After=network.target

[Service]
User=vagrant
Group=vagrant
WorkingDirectory=/home/vagrant/myproject
ExecStart=/usr/local/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 --certfile /etc/ssl/certs/nginx-selfsigned.crt --keyfile /etc/ssl/private/nginx-selfsigned.key app:app
Restart=always

[Install]
WantedBy=multi-user.target
EMD

# =================================================================
# 				6. Start and Enable Gunicorn service
# =================================================================
sudo systemctl daemon-reload
sudo systemctl start gunicorn.service
sudo systemctl enable gunicorn.service

# =================================================================
# 				7. Configure Firewall
# =================================================================
echo "--> Configuring firewall..."
sudo firewall-cmd --permanent --zone=public --add-port=5000/tcp
sudo firewall-cmd --reload
# =================================================================
# 		7.Verify that gunicorn service is running and port is open
# =================================================================
echo "--> Verifying gunicorn port listening:"
sudo ss -tnlp | grep 5000  && echo " gunicorn is listening on port 5000"

echo "--- Web Server ($(hostname)) Provisioning Complete ✓ ---"