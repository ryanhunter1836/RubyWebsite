import 'tempusdominus-bootstrap-4'

function addDays(date, days) {
    const copy = new Date(Number(date))
    copy.setDate(date.getDate() + days)
    return copy
}

function formatDate(date) {
    var y = date.getFullYear().toString();
    var m = (date.getMonth() + 1).toString();
    var d = date.getDate().toString();
    (d.length == 1) && (d = '0' + d);
    (m.length == 1) && (m = '0' + m);
    var yyyymmdd = y + "-" + m + "-" + d;
    return yyyymmdd;
}

function getCustomerInfo(userEmail) {
    $.get("/api/query_user", { email: userEmail }, function(data) {

      if(data.success) {
          clearTables();

          $("#id_field").text(data.user_info.id);
          $("#name_field").text(data.user_info.name);
          $("#email_field").text(data.user_info.email);
          $("#actived_field").text(data.user_info.activated);
          $("#actived_at_field").text(data.user_info.actived_at);
          $("#customer_id_field").text(data.user_info.stripe_customer_id);

          $("#address1_field").text(data.shipping.address1);
          $("#address2_field").text(data.shipping.address2);
          $("#city_field").text(data.shipping.city);
          $("#state_field").text(data.shipping.state);
          $("#postal_field").text(data.shipping.postal);

          data.orders.forEach(order => (addOrder(order)));
      }
  });
}

function clearTables() {
    $("#id_field").text("");
        $("#name_field").text("");
        $("#email_field").text("");
        $("#actived_field").text("");
        $("#actived_at_field").text("");
        $("#customer_id_field").text("");

        $("#address1_field").text("");
        $("#address2_field").text("");
        $("#city_field").text("");
        $("#state_field").text("");
        $("#postal_field").text("");

        $(".order_row").remove();
}

function getVehicleDetails(vehicleId) {
    $.get("/api/query_vehicle", { id: vehicleId }, function(data) {
        if(data.success) {
            $("#vehicle_id_field").text(data.vehicle.id);
            $("#make_field").text(data.vehicle.make);
            $("#model_field").text(data.vehicle.model);
            $("#year_field").text(data.vehicle.year);
            $("#driver_front_field").text(data.vehicle.driver_front);
            $("#passenger_front_field").text(data.vehicle.passenger_front);
            $("#rear_field").text(data.vehicle.rear);
        }
        else {
            $("#vehicle_id_field").text("");
            $("#make_field").text("");
            $("#model_field").text("");
            $("#year_field").text("");
            $("#driver_front_field").text("");
            $("#passenger_front_field").text("");
            $("#rear_field").text("");
        }
    });
}


function addOrder(order) {
    let htmlToInsert = "<tr class='order_row'>" +
    `<td>${order.frequency}</td>` +
    `<td>${order.wipertype}</td>` +
    `<td>${order.total_price}</td>` +
    `<td>${order.subscription_id}</td>` +
    `<td>${order.vehicle_id}</td>` +
    `<td>${order.cycle_anchor}</td>` +
    `<td>${order.next_shipment_date}</td></tr>`;

    $("#order_options_table").append(htmlToInsert);
}

function saveChanges() {
    //Build a list of all the orders and their completion status
    var orders = []
    $(".order").each(function(e) {
        var id = $(this).find(".id").text();
        var complete = $(this).find(".complete").is(":checked");
        orders.push({ id: id, complete: complete });
    });

    fetch('/api/save_order_status', {
        method: 'post',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
            changes: orders,
        })
        }).then((response) => {
            console.log("success");
        });

    // $.post("/api/save_order_status", { changes: orders })
}

$(document).ready(function() {
    var date =  $("#start-date").val().split("-");
    let currentDate = new Date(date[0], date[1] - 1, date[2]);

    var date =  $("#end-date").val().split("-");
    let futureDate = new Date(date[0], date[1] - 1, date[2]);

    $('#datetimepicker').datetimepicker({
        format: 'L',
        defaultDate: currentDate
    });

    $('#datetimepicker2').datetimepicker({
        format: 'L',
        defaultDate: futureDate
    });

    $("#datetimepicker").on("hide.datetimepicker", function(e) { 
        var date = $("#selected-start-date").val().split("/");
        //Only take the first 4 digits in the year (in case a time was appended to the end)
        date[2] = date[2].substring(0,4);
        var startDate = formatDate(new Date(date[2], date[0] - 1, date[1]));
        $("#datetimepicker2").datetimepicker('minDate', new Date(date[2], date[0] - 1, date[1]));
        
        date =  $("#selected-end-date").val().split("/");
        var endDate = formatDate(new Date(date[2], date[0] - 1, date[1]));
        $("#datetimepicker").datetimepicker('maxDate', new Date(date[2], date[0] - 1, date[1]));

        $("#date-search").attr("href", `/users?finish=${endDate}&start=${startDate}`);
    })

    $("#datetimepicker2").on("hide.datetimepicker", function(e) {
        var date = $("#selected-start-date").val().split("/");
        //Only take the first 4 digits in the year (in case a time was appended to the end)
        date[2] = date[2].substring(0,4);
        var startDate = formatDate(new Date(date[2], date[0] - 1, date[1]));
        $("#datetimepicker2").datetimepicker('minDate', new Date(date[2], date[0] - 1, date[1]));
        
        date =  $("#selected-end-date").val().split("/");
        var endDate = formatDate(new Date(date[2], date[0] - 1, date[1]));
        $("#datetimepicker").datetimepicker('maxDate', new Date(date[2], date[0] - 1, date[1]));

        $("#date-search").attr("href", `/users?finish=${endDate}&start=${startDate}`);
    })

    $("#user-search-button").click(function() {
        getCustomerInfo($("#username").val())
    })

    $("#vehicle-search-button").click(function() {
        getVehicleDetails($("#vehicle").val());
    });

    $("#save-orders-button").click(function() {
        saveChanges();
    })
});