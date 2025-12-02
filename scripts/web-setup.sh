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

        :root {
            --primary-dark-blue: #2c3e50; 
            --primary-teal: #1abc9c;   
            --accent-blue: #3498db;     
            --background-light: #ecf0f1;
            --card-background: #ffffff; 
            --text-dark: #333333;      
            --text-muted: #7f8c8d;     
            --border-color: #e0e0e0;   
            --table-header-bg: #f2f4f6;
            --table-hover-bg: #eaf2f8;  

            /* ألوان التنبيهات */
            --success-bg: #d4edda;
            --success-color: #155724;
            --danger-bg: #f8d7da;
            --danger-color: #721c24;
            --info-bg: #d1ecf1;
            --info-color: #0c5460;
        }

        body {
            background-color: var(--background-light);
            font-family: 'Inter', sans-serif; 
            color: var(--text-dark);
            line-height: 1.6;
        }

        .navbar {
            background-color: var(--primary-dark-blue); 
            box-shadow: 0 3px 8px rgba(0,0,0,0.15);
            padding-top: 1rem;
            padding-bottom: 1rem;
        }
        .navbar .navbar-brand {
            color: var(--card-background) !important;
            font-weight: 700; /* خط سميك */
            font-size: 1.5rem;
        }

        .container {
            max-width: 1100px; /* زيادة عرض الحاوية */
            margin-top: 40px;
            margin-bottom: 40px;
        }

        .card {
            background-color: var(--card-background);
            border-radius: 1rem; /* حواف مستديرة أكثر */
            box-shadow: 0 8px 20px rgba(0,0,0,0.1); /* ظل أقوى وأكثر انتشاراً */
            border: none;
            overflow: hidden; /* لضمان أن الحواف المستديرة تعمل مع المحتوى */
        }

        .table {
            margin-bottom: 0; /* إزالة الهامش السفلي للجدول داخل البطاقة */
        }
        .table-hover tbody tr:hover {
            background-color: var(--table-hover-bg);
            cursor: pointer;
        }
        th {
            font-weight: 600;
            color: var(--text-dark);
            background-color: var(--table-header-bg);
            border-bottom: 2px solid var(--border-color);
        }
        td {
            padding: 1rem 0.75rem; /* تباعد أكبر للخلايا */
        }

        /* ألوان الأزرار */
        .btn-primary {
            background-color: var(--primary-teal);
            border-color: var(--primary-teal);
            font-weight: 600;
            padding: 0.75rem 1.25rem;
            border-radius: 0.5rem;
            transition: background-color 0.3s ease, border-color 0.3s ease;
        }
        .btn-primary:hover {
            background-color: #16a085; /* درجة أغمق */
            border-color: #16a085;
        }
        .btn-info { /* زر التعديل */
            background-color: var(--accent-blue);
            border-color: var(--accent-blue);
            color: white;
            border-radius: 0.5rem;
        }
        .btn-info:hover {
            background-color: #2980b9;
            border-color: #2980b9;
        }
        .btn-danger {
            background-color: #e74c3c; /* أحمر للحذف */
            border-color: #e74c3c;
            border-radius: 0.5rem;
        }
        .btn-danger:hover {
            background-color: #c0392b;
            border-color: #c0392b;
        }
        .btn-success { /* زر حفظ التعديلات */
            background-color: var(--primary-teal);
            border-color: var(--primary-teal);
            font-weight: 600;
            border-radius: 0.5rem;
        }
        .btn-success:hover {
            background-color: #16a085;
            border-color: #16a085;
        }

        /* تنسيقات التنبيهات المخصصة */
        .custom-alert {
            position: fixed;
            top: 25px; /* أعلى قليلاً */
            left: 50%;
            transform: translateX(-50%);
            z-index: 1060;
            padding: 18px 25px; /* تباعد أكبر */
            border-radius: 0.75rem; /* حواف مستديرة أكثر */
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            display: none;
            max-width: 450px; /* عرض أكبر قليلاً */
            text-align: center;
            font-size: 1.05rem;
            font-weight: 500;
        }
        .custom-alert.alert-success { background-color: var(--success-bg); color: var(--success-color); border: 1px solid #a3e0b2; }
        .custom-alert.alert-danger { background-color: var(--danger-bg); color: var(--danger-color); border: 1px solid #f2b1b1; }
        .custom-alert.alert-info { background-color: var(--info-bg); color: var(--info-color); border: 1px solid #a7d9e7; }

        /* تنسيقات الـ Modals */
        .modal-content {
            border-radius: 1rem;
            box-shadow: 0 10px 30px rgba(0,0,0,0.15);
            border: none;
        }
        .modal-header {
            background-color: var(--primary-dark-blue);
            color: white;
            border-bottom: none;
            border-top-left-radius: 1rem;
            border-top-right-radius: 1rem;
            padding: 1.5rem;
        }
        .modal-header .btn-close {
            filter: invert(1); /* لجعل زر الإغلاق أبيض */
        }
        .modal-title {
            font-weight: 600;
        }
        .modal-body {
            padding: 2rem;
        }
        .modal-footer {
            border-top: 1px solid var(--border-color);
            padding: 1.5rem;
            justify-content: center;
        }
        .custom-confirm-modal .modal-footer button {
            width: 120px; /* عرض متناسق للأزرار */
            font-weight: 500;
        }

        /* تنسيقات بطاقات الإحصائيات */
        .stats-card {
            background-color: var(--card-background);
            border: 1px solid var(--border-color);
            padding: 25px;
            text-align: center;
            border-radius: 1rem;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
            height: 100%; /* لضمان نفس الارتفاع */
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        .stats-card:hover {
            transform: translateY(-7px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.12);
        }
        .stats-card h4 {
            color: var(--primary-teal);
            margin-bottom: 8px;
            font-size: 2.2rem;
            font-weight: 700;
        }
        .stats-card h4 i {
            color: var(--accent-blue); /* لون الأيقونات في البطاقات */
        }
        .stats-card p {
            font-size: 1rem;
            color: var(--text-muted);
            margin-bottom: 0;
            font-weight: 500;
        }
        .text-muted {
            color: var(--text-muted) !important;
        }
        .form-control {
            border-radius: 0.5rem;
            padding: 0.75rem 1rem;
            border: 1px solid var(--border-color);
        }
        .form-control:focus {
            border-color: var(--primary-teal);
            box-shadow: 0 0 0 0.25rem rgba(26, 188, 156, 0.25); /* ظل تركيز بلون Primary Teal */
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="#">
                <i class="fas fa-users me-2"></i>نظام إدارة الموظفين
            </a>
        </div>
    </nav>

    <div class="container">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="h2" style="color: var(--primary-dark-blue); font-weight: 700;">قائمة الموظفين</h1>
                <p id="server-hostname" class="text-muted">جاري التحميل...</p>
            </div>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addEmployeeModal">
                <i class="fas fa-plus me-2"></i>إضافة موظف جديد
            </button>
        </div>

        <div class="row mb-5">
            <div class="col-md-12"> <!-- تم تعديل هذا العمود ليشغل العرض الكامل -->
                <div class="stats-card">
                    <h4><span id="total-employees">0</span></h4>
                    <p>إجمالي الموظفين</p>
                </div>
            </div>
            <!-- تم حذف جزئي "متوسط الرواتب" و "أداء الموظفين" -->
        </div>

        <div class="card shadow-sm">
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead class="table-light">
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

    <!-- Add Employee Modal -->
    <div class="modal fade" id="addEmployeeModal" tabindex="-1" aria-labelledby="addEmployeeModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="addEmployeeModalLabel">إضافة موظف جديد</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form id="add-employee-form">
                        <div class="mb-3">
                            <input type="text" class="form-control" id="add-name" placeholder="الاسم" required>
                        </div>
                        <div class="mb-3">
                            <input type="text" class="form-control" id="add-phone" placeholder="رقم الهاتف">
                        </div>
                        <div class="mb-3">
                            <input type="email" class="form-control" id="add-email" placeholder="البريد الإلكتروني">
                        </div>
                        <div class="mb-3">
                            <input type="text" class="form-control" id="add-position" placeholder="الوظيفة">
                        </div>
                        <div class="mb-3">
                            <input type="number" class="form-control" id="add-salary" placeholder="الراتب">
                        </div>
                        <button type="submit" class="btn btn-primary w-100"><i class="fas fa-save me-2"></i>إضافة</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Edit Employee Modal -->
    <div class="modal fade" id="editEmployeeModal" tabindex="-1" aria-labelledby="editEmployeeModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="editEmployeeModalLabel">تعديل بيانات الموظف</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form id="edit-employee-form">
                        <input type="hidden" id="edit-id">
                        <div class="mb-3">
                            <label for="edit-name" class="form-label visually-hidden">الاسم</label>
                            <input type="text" class="form-control" id="edit-name" required placeholder="الاسم">
                        </div>
                        <div class="mb-3">
                            <label for="edit-phone" class="form-label visually-hidden">رقم الهاتف</label>
                            <input type="text" class="form-control" id="edit-phone" placeholder="رقم الهاتف">
                        </div>
                        <div class="mb-3">
                            <label for="edit-email" class="form-label visually-hidden">البريد الإلكتروني</label>
                            <input type="email" class="form-control" id="edit-email" placeholder="البريد الإلكتروني">
                        </div>
                        <div class="mb-3">
                            <label for="edit-position" class="form-label visually-hidden">الوظيفة</label>
                            <input type="text" class="form-control" id="edit-position" placeholder="الوظيفة">
                        </div>
                        <div class="mb-3">
                            <label for="edit-salary" class="form-label visually-hidden">الراتب</label>
                            <input type="number" class="form-control" id="edit-salary" placeholder="الراتب">
                        </div>
                        <button type="submit" class="btn btn-success w-100"><i class="fas fa-check-circle me-2"></i>حفظ التعديلات</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Custom Alert/Notification Message -->
    <div id="custom-alert-message" class="custom-alert" role="alert"></div>

    <!-- Custom Confirm Modal for Delete -->
    <div class="modal fade custom-confirm-modal" id="confirmDeleteModal" tabindex="-1" aria-labelledby="confirmDeleteModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-sm">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="confirmDeleteModalLabel">تأكيد الحذف</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body text-center">
                    <i class="fas fa-exclamation-triangle text-danger mb-3" style="font-size: 2.5rem; color: #e74c3c;"></i><br>
                    هل أنت متأكد من رغبتك في حذف هذا الموظف؟<br>لا يمكن التراجع عن هذا الإجراء.
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

            function showAlert(message, type = 'info', duration = 3000) {
                const alertBox = $('#custom-alert-message');
                alertBox.removeClass('alert-success alert-danger alert-info').addClass(`alert-${type}`);
                alertBox.text(message).fadeIn();
                setTimeout(() => {
                    alertBox.fadeOut();
                }, duration);
            }

            $.ajax({
                url: `${baseUrl}/hostname`,
                type: 'GET',
                success: function(data) {
                    const hostname = data.hostname || 'Local Server';
                    $('#server-hostname').text('الخادم: ' + hostname);
                },
                error: function(jqXHR, textStatus, errorThrown) {
                    console.error("Error fetching hostname:", textStatus, errorThrown);
                    $('#server-hostname').text('الخادم: غير معروف'); // Fallback
                    showAlert("فشل في جلب اسم الخادم.", "danger");
                }
            });

            function fetchEmployees() {
                $.get(apiUrl)
                .done(function(data) {
                    $('#employee-list').empty();
                    $('#total-employees').text(data.length); // تحديث إجمالي الموظفين

                    if (data.length === 0) {
                        $('#employee-list').append('<tr><td colspan="6" class="text-center py-4">لا توجد بيانات موظفين حاليًا.</td></tr>');
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
                                        <button class="btn btn-sm btn-info edit-btn me-2" data-id="${emp.id}" data-bs-toggle="modal" data-bs-target="#editEmployeeModal" title="تعديل"><i class="fas fa-edit"></i></button>
                                        <button class="btn btn-sm btn-danger delete-btn" data-id="${emp.id}" title="حذف"><i class="fas fa-trash-alt"></i></button>
                                    </td>
                                </tr>
                            `);
                        });
                    }
                })
                .fail(function(jqXHR, textStatus, errorThrown) {
                    console.error("Error fetching employees:", textStatus, errorThrown);
                    showAlert("فشل في جلب بيانات الموظفين. الرجاء التحقق من اتصال الخادم.", "danger");
                });
            }

            $('#add-employee-form').submit(function(e) {
                e.preventDefault();
                const newEmployee = {
                    name: $('#add-name').val(),
                    phone: $('#add-phone').val(),
                    email: $('#add-email').val(),
                    position: $('#add-position').val(),
                    salary: $('#add-salary').val()
                };
                $.ajax({
                    url: apiUrl,
                    type: 'POST',
                    contentType: 'application/json',
                    data: JSON.stringify(newEmployee),
                    success: function() {
                        fetchEmployees();
                        $('#addEmployeeModal').modal('hide');
                        $('#add-employee-form')[0].reset();
                        showAlert("تمت إضافة الموظف بنجاح.", "success");
                    },
                    error: function(jqXHR, textStatus, errorThrown) {
                        console.error("Error adding employee:", textStatus, errorThrown);
                        showAlert("فشل في إضافة الموظف. الرجاء التحقق من اتصال الخادم والبيانات المدخلة.", "danger");
                    }
                });
            });

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
                        url: `${apiUrl}/${id}`,
                        type: 'DELETE',
                        success: function() {
                            fetchEmployees();
                            showAlert("تم حذف الموظف بنجاح.", "success");
                            $('#confirmDeleteModal').modal('hide');
                        },
                        error: function(jqXHR, textStatus, errorThrown) {
                            console.error("Error deleting employee:", textStatus, errorThrown);
                            showAlert("فشل في حذف الموظف. الرجاء التحقق من اتصال الخادم.", "danger");
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
                const updatedEmployee = {
                    name: $('#edit-name').val(),
                    phone: $('#edit-phone').val(),
                    email: $('#edit-email').val(),
                    position: $('#edit-position').val(),
                    salary: $('#edit-salary').val()
                };
                $.ajax({
                    url: `${apiUrl}/${id}`,
                    type: 'PUT',
                    contentType: 'application/json',
                    data: JSON.stringify(updatedEmployee),
                    success: function() {
                        fetchEmployees();
                        $('#editEmployeeModal').modal('hide');
                        showAlert("تم تحديث بيانات الموظف بنجاح.", "success");
                    },
                    error: function(jqXHR, textStatus, errorThrown) {
                        console.error("Error updating employee:", textStatus, errorThrown);
                        showAlert("فشل في تحديث بيانات الموظف. الرجاء التحقق من اتصال الخادم والبيانات المدخلة.", "danger");
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
