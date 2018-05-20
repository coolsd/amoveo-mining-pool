lookup_account1();
function lookup_account1() {
    document.body.appendChild(document.createElement("br"));
    var lookup_account = document.createElement("div");
    document.body.appendChild(lookup_account);
    var lookup_account_address = document.createElement("INPUT");
    lookup_account_address.setAttribute("type", "text");
    var input_info = document.createElement("h8");
    input_info.innerHTML = "pubkey: ";
    document.body.appendChild(input_info);
    document.body.appendChild(lookup_account_address);

    var lookup_account_button = document.createElement("BUTTON");
    var lookup_account_text_node = document.createTextNode("lookup account");
    lookup_account_button.appendChild(lookup_account_text_node);
    lookup_account_button.onclick = lookup_account_helper;
    document.body.appendChild(lookup_account_button);
    function lookup_account_helper() {
        var x = lookup_account_address.value;
        console.log("lookup account");
        variable_public_get(["account", x], lookup_account_helper2);
        variable_public_get(["miner_detail", x], lookup_account_helper3);
    }
    function lookup_account_helper2(x) {
        console.log(x);
        var veo = x[2];
        var shares = x[3];
        lookup_account.innerHTML = "<h3>Account Status 账户信息</h3>veo: ".concat(veo / 100000000).concat(" shares: ").concat(shares);
    }

    function lookup_account_helper3(x) {
        console.log(x);
        var recent_share = x[1];
        var online_workers = x[2];
        var diff = x[3];
        //TODO
        //calulate hashrates by diff
        lookup_account.innerHTML = lookup_account.innerHTML.
            concat("</br>Online workers: ").concat(online_workers).
            concat("    Recent shares: ").concat(recent_share).
            concat("   Total hashrates: ").concat((0.08473684211*recent_share).toFixed(2)).
            concat(" GH/s");

        var table_HTML = "".
            concat("<table border=1>").
            concat("<tr><th>Worker</th><th>Recent Share</th><th>Hashrates</th></tr>");

        var online_workers_list = x[4];
        online_workers_list.shift(); //remove first element
        for (i in online_workers_list) {
            var worker_info = online_workers_list[i]; 
            var worker_name = worker_info[1];
            worker_name.shift();
            for (y in worker_name) {
                worker_name[y] = String.fromCharCode(worker_name[y]);
            }
            worker_name = worker_name.join("");
            var worker_share = worker_info[2];
            var hashrates = (0.08473684211*worker_share).toFixed(2);
            table_HTML = table_HTML.
            concat("<tr>").
            concat("<td>").concat(worker_name).concat("</td>").
            concat("<td>").concat(worker_share).concat("</td>").
            concat("<td>").concat(hashrates).concat(" Gh/s</td>").
            concat("</tr>");
        }
        table_HTML = table_HTML.concat("</table>");
        lookup_account.innerHTML = lookup_account.innerHTML.concat(table_HTML);
    }

}
