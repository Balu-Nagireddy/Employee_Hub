def test_list_employees_empty(client):
    response = client.get("/employees")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 0
    assert data["items"] == []


def test_create_employee(client):
    payload = {
        "employee_code": "EMP001",
        "name": "John Doe",
        "email": "john@example.com",
        "department": "Engineering",
        "designation": "Senior Engineer",
        "salary": 75000.0,
        "status": "active",
    }
    response = client.post("/employees", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["employee_code"] == "EMP001"
    assert data["name"] == "John Doe"
    assert data["id"] is not None


def test_create_duplicate_employee(client):
    payload = {
        "employee_code": "EMP001",
        "name": "John Doe",
        "email": "john@example.com",
        "department": "Engineering",
        "designation": "Senior Engineer",
        "salary": 75000.0,
    }
    client.post("/employees", json=payload)
    response = client.post("/employees", json=payload)
    assert response.status_code == 409


def test_get_employee(client):
    payload = {
        "employee_code": "EMP002",
        "name": "Jane Doe",
        "email": "jane@example.com",
        "department": "Engineering",
        "designation": "Engineer",
        "salary": 65000.0,
    }
    create_resp = client.post("/employees", json=payload)
    emp_id = create_resp.json()["id"]

    response = client.get(f"/employees/{emp_id}")
    assert response.status_code == 200
    assert response.json()["name"] == "Jane Doe"


def test_get_employee_not_found(client):
    response = client.get("/employees/99999")
    assert response.status_code == 404


def test_update_employee(client):
    payload = {
        "employee_code": "EMP003",
        "name": "Bob Smith",
        "email": "bob@example.com",
        "department": "Engineering",
        "designation": "Engineer",
        "salary": 60000.0,
    }
    create_resp = client.post("/employees", json=payload)
    emp_id = create_resp.json()["id"]

    update = {"name": "Robert Smith", "salary": 70000.0}
    response = client.put(f"/employees/{emp_id}", json=update)
    assert response.status_code == 200
    assert response.json()["name"] == "Robert Smith"
    assert response.json()["salary"] == 70000.0


def test_delete_employee(client):
    payload = {
        "employee_code": "EMP004",
        "name": "Alice Brown",
        "email": "alice@example.com",
        "department": "Engineering",
        "designation": "Engineer",
        "salary": 60000.0,
    }
    create_resp = client.post("/employees", json=payload)
    emp_id = create_resp.json()["id"]

    response = client.delete(f"/employees/{emp_id}")
    assert response.status_code == 204

    get_response = client.get(f"/employees/{emp_id}")
    assert get_response.status_code == 404


def test_health_endpoint(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_ready_endpoint(client):
    response = client.get("/ready")
    assert response.status_code == 200


def test_live_endpoint(client):
    response = client.get("/live")
    assert response.status_code == 200
    assert response.json()["status"] == "alive"
