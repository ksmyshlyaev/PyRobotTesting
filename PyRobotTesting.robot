*** Settings ***
Library  RequestsLibrary
Library  DatabaseLibrary
Library  String
Library  Collections
Library  MyKeywords.py

*** Variables ***
${Base_URL}  http://localhost:5000

*** Test Cases ***
MyTestCase
#   Step 1
    log  Step 1
    connect to database using custom params  sqlite3    database='C:/Users/Konstantin/PyRobotApp/testing-master/web/clients.db', isolation_level=None

#   Step 2
    log  Step 2
    @{client_id_with_positive_balance}=  query  SELECT CLIENTS.CLIENT_ID FROM CLIENTS JOIN BALANCES ON CLIENTS.CLIENT_ID=BALANCES.CLIENTS_CLIENT_ID WHERE BALANCES.BALANCE>0 ORDER BY BALANCES.BALANCE DESC LIMIT 1;
    run keyword if  @{client_id_with_positive_balance}==[]  Add_rich_client
    ${client_id_with_positive_balance}=  query  SELECT CLIENTS.CLIENT_ID FROM CLIENTS JOIN BALANCES ON CLIENTS.CLIENT_ID=BALANCES.CLIENTS_CLIENT_ID WHERE BALANCES.BALANCE>0 ORDER BY BALANCES.BALANCE DESC LIMIT 1;
    ${initial_client_balance}=  query  SELECT BALANCES.BALANCE FROM CLIENTS JOIN BALANCES ON CLIENTS.CLIENT_ID=BALANCES.CLIENTS_CLIENT_ID WHERE BALANCES.BALANCE>0 ORDER BY BALANCES.BALANCE DESC LIMIT 1;
    ${client_id_with_positive_balance_clean}=  set variable  ${client_id_with_positive_balance[0][0]}
    ${initial_client_balance_clean}=  set variable  ${initial_client_balance[0][0]}
    log  initial client balance is: ${initial_client_balance_clean}
    log  client id is: ${client_id_with_positive_balance_clean}

#   Step 3
    log  Step 3
    create session  local_session  ${Base_URL}
    ${body}=  create dictionary  client_id=${client_id_with_positive_balance_clean}
    ${header}=  create dictionary  Content-Type=application/json
    ${response}=  POST REQUEST  local_session  /client/services  data=${body}  headers=${header}
    Should Be Equal As Integers  ${response.status_code}  200  Server sent incorrect status code
    ${list_of_services_added_to_client}=  Get_list_of_services_from_json  ${response.content}

#   Step 4
    log  Step 4
    ${response}=  GET REQUEST  local_session  /services
    Should Be Equal As Integers  ${response.status_code}  200  Server sent incorrect status code
    ${list_of_all_serives}=  Get_list_of_services_from_json  ${response.content}

#   Step 5
    log  Step 5
    ${unadded_service_id}  ${unadded_service_cost}=  Get_unadded_service  ${list_of_all_serives}  ${list_of_services_added_to_client}
    log  unadded service id is: ${unadded_service_id}
    log  unadded service cost is: ${unadded_service_cost}

#   Step 6
    log  Step 6
    ${body}=  create dictionary  client_id=${client_id_with_positive_balance_clean}  service_id=${unadded_service_id}
    ${header}=  create dictionary  Content-Type=application/json
    ${response}=  POST REQUEST  local_session  /client/add_service  data=${body}  headers=${header}
    log  ${response.content}
    Should Be Equal As Integers  ${response.status_code}  202  Server sent incorrect status code

#   Step 7
    log  Step 7
    ${success}=  Check_if_service_was_added  ${client_id_with_positive_balance_clean}  ${unadded_service_id}
    should be equal as strings  ${success}  OK  Service was not added to the client

#   Step 8
    log  Step 8
    ${end_client_balance}=  query  SELECT BALANCES.BALANCE FROM CLIENTS JOIN BALANCES ON CLIENTS.CLIENT_ID=BALANCES.CLIENTS_CLIENT_ID WHERE CLIENTS.CLIENT_ID=${client_id_with_positive_balance_clean};
    ${end_client_balance_clean}=  set variable  ${end_client_balance[0][0]}
    log  end balance of the client is: ${end_client_balance_clean}

#   Step 9
    log  Step 9
    ${changed_client_balance}=  evaluate  ${initial_client_balance_clean} - ${unadded_service_cost}
    SHOULD BE EQUAL AS NUMBERS  ${end_client_balance_clean}  ${changed_client_balance}  End client balance is not equal to difference of initial balance and service cost

*** Keywords ***
Get_list_of_services_from_json
    [Arguments]  ${source_data}
    ${source_data}=    Evaluate     json.loads("""${source_data}""")    json
    ${all_items}=    Set Variable     ${source_data['items']}
    [Return]  ${all_items}

Get_unadded_service
    [Arguments]  ${list_of_all_services}  ${list_of_services_added_to_client}
    ${list_of_all_services}=  convert to string  ${list_of_all_services}
    ${list_of_services_added_to_client}=  convert to string  ${list_of_services_added_to_client}
    ${unadded_service_id}=  get_unadded_service_id  ${list_of_all_services}  ${list_of_services_added_to_client}
    ${unadded_service_cost}=  get_unadded_service_cost  ${unadded_service_id}  ${list_of_all_services}
    [Return]  ${unadded_service_id}  ${unadded_service_cost}

Add_rich_client
    log  There was no client with positive balance in DB, adding new one
    ${new_client_id}=  Get_new_client_id
    query  INSERT INTO CLIENTS (CLIENT_ID, CLIENT_NAME) VALUES (${new_client_id}, "Tony Stark");
    query  INSERT INTO BALANCES (CLIENTS_CLIENT_ID, BALANCE) VALUES (${new_client_id}, 5.00);
    log  client with positive balance was added, client id is: ${new_client_id}

Get_new_client_id
    ${client_id_max_number}=  query    SELECT CLIENT_ID FROM CLIENTS ORDER BY CLIENT_ID DESC LIMIT 1;
    ${client_id_max_number_clean}=  set variable if  @{client_id_max_number}==[]  1  ${client_id_max_number[0][0]}
    log  ${client_id_max_number_clean}
    ${client_id_max_number_balance}=  query    SELECT CLIENTS_CLIENT_ID FROM BALANCES ORDER BY CLIENTS_CLIENT_ID DESC LIMIT 1;
    ${client_id_max_number_balance_clean}=  set variable if  @{client_id_max_number_balance}==[]  1  ${client_id_max_number_balance[0][0]}
    log  ${client_id_max_number_balance_clean}
    ${client_id_max_number_service}=  query    SELECT CLIENTS_CLIENT_ID FROM CLIENT_SERVICE ORDER BY CLIENTS_CLIENT_ID DESC LIMIT 1;
    ${client_id_max_number_service_clean}=  set variable if  @{client_id_max_number_service}==[]  1  ${client_id_max_number_service[0][0]}
    log  ${client_id_max_number_service_clean}
    ${largest_id}=  largest  ${client_id_max_number_clean}  ${client_id_max_number_balance_clean}  ${client_id_max_number_service_clean}
    ${probable_new_client_id}=  Evaluate  ${largest_id} + 1
    ${new_client_id}=  set variable if  (${client_id_max_number_clean}==1)and(${client_id_max_number_balance_clean}==1)and(${client_id_max_number_service_clean}==1)  1  ${probable_new_client_id}
    [Return]  ${new_client_id}

Check_if_service_was_added
    [Arguments]  ${client_id_with_positive_balance_clean}  ${unadded_service_id}
    [Timeout]    1min
    ${success}=  check_service_added  ${client_id_with_positive_balance_clean}  ${unadded_service_id}
    [Return]  ${success}