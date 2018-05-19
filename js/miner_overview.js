(function miner_overview() {
    document.body.appendChild(document.createElement("br"));
    document.body.appendChild(document.createElement("br"));
    document.body.appendChild(document.createElement("br"));
    var div = document.createElement("div");
    document.body.appendChild(div);

    var text2 = document.createElement("h8");
	variable_public_get(["miner_overview"], function(x) {
        console.log(x);
        var total_share = x[1];
        var total_account = x[2];

	    text2.innerHTML = "Recent shares: ".concat(total_share).
            concat("   Active acounts: ").concat(total_account).
            concat("   Total hashrates: ").concat((0.08473684211*total_share).toFixed(2)).
            concat(" GH/s");
	});
    div.appendChild(text2);
})();
