import json
import requests


def get_unadded_service_id(list_of_all_services, list_of_all_services_added_to_client):
    dirty_string_of_all_services = str(list_of_all_services)
    clean_string_of_all_services = dirty_string_of_all_services.replace("'", "\"")
    all_services_json = json.loads(clean_string_of_all_services)

    dirty_string_of_all_services_added_to_client = str(list_of_all_services_added_to_client)
    clean_string_of_all_services_added_to_client = dirty_string_of_all_services_added_to_client.replace("'", "\"")
    client_services_json = json.loads(clean_string_of_all_services_added_to_client)

    unadded_service = {}
    for service in all_services_json:
        if service not in client_services_json:
            unadded_service = service
            break

    return unadded_service['id']


def get_unadded_service_cost(id, list_of_all_services):
    dirty_string_of_all_services = str(list_of_all_services)
    clean_string_of_all_services = dirty_string_of_all_services.replace("'", "\"")
    all_services_json = json.loads(clean_string_of_all_services)
    cost = 0.0
    for service in all_services_json:
        if service['id'] == id:
            cost = service['cost']
            break
    return cost


def largest(num1, num2, num3):
    numbers_list = [num1, num2, num3]
    return max(numbers_list)


def check_service_added(client_id, added_service_id):
    success = None
    while success is None:
        data = {"client_id": client_id}
        response = requests.post("http://localhost:5000/client/services", headers={'Content-Type': 'application/json'}, data=json.dumps(data))
        response_string = response.text
        response_parsed_string = json.loads(response_string)
        items = response_parsed_string["items"]
        for i in items:
            if i["id"] == added_service_id:
                success = "OK"
                return success
