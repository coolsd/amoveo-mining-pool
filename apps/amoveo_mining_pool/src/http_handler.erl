
-module(http_handler).
-export([init/3, handle/2, terminate/3, doit/1]).
init(_Type, Req, _Opts) -> {ok, Req, no_state}.
terminate(_Reason, _Req, _State) -> ok.
handle(Req, State) ->
    {ok, Data0, Req2} = cowboy_req:body(Req),
    {{IP, _}, Req3} = cowboy_req:peer(Req2),
    %io:fwrite("http handler got message: "),
    %io:fwrite(Data0),
    %io:fwrite("\n"),
	Data1 = handle_worker_id(Data0),
    Data = packer:unpack(Data1),
    case Data of
	{work, _, _} ->
	    %io:fwrite("work from IP "),
	    %io:fwrite(packer:pack(IP)),
	    %io:fwrite("\n"),
	    %io:fwrite(Data0),
	    %io:fwrite("\n"),
	    ok;
	_ -> ok
    end,
    D0 = doit(Data),
    D = packer:pack(D0),
    Headers=[{<<"content-type">>,<<"application/octet-stream">>},
    {<<"Access-Control-Allow-Origin">>, <<"*">>}],
    {ok, Req4} = cowboy_req:reply(200, Headers, D, Req3),
    {ok, Req4, State}.
doit({account, 2}) ->
    D = accounts:check(),%duplicating the database here is no good. It will be slow if there are too many accounts.
    {ok, dict:fetch(total, D)};
doit({account, Pubkey}) -> 
    accounts:balance(Pubkey);
doit({mining_data, _, WorkerIDBin}) -> 
	io:fwrite("Got mining_data "),
	io:fwrite(" WorkerID "),
	WorkerID = binary_to_list(WorkerIDBin),
	io:fwrite(WorkerID),
	io:fwrite("\n"),
    {ok, [Hash, Nonce, Diff]} = 
	mining_pool_server:problem_api_mimic(),
    {ok, [Hash, Diff, Diff]};
doit({mining_data, _}) -> 
    {ok, [Hash, Nonce, Diff]} = 
	mining_pool_server:problem_api_mimic(),
    {ok, [Hash, Diff, Diff]};
doit({mining_data}) -> 
    mining_pool_server:problem_api_mimic();
doit({work, Nonce, Pubkey, WorkerIDBin}) ->
    %io:fwrite("attempted work \n"),
	io:fwrite("Got work with "),
	io:fwrite(" WorkerID "),
	WorkerID = binary_to_list(WorkerIDBin),
	io:fwrite(WorkerID),
	io:fwrite("\n"),
    mining_pool_server:receive_work(Nonce, Pubkey, WorkerID);
doit({work, Nonce, Pubkey}) ->
    %io:fwrite("attempted work \n"),
    mining_pool_server:receive_work(Nonce, Pubkey);
doit({miner_overview}) ->
	{ok, workers:miner_overview()};
doit({miner_detail, Pubkey}) ->
	{ok, workers:miner_detail(Pubkey)}.
handle_worker_id(D) -> 
	E = jiffy:decode(D),
	%K = hd(E),
	case E of
		[<<"mining_data">>, PubkeyWithWorkderID] ->
			PubkeyWithWorkderIDStr = binary_to_list(PubkeyWithWorkderID),
			IsHavePoint = string:chr(PubkeyWithWorkderIDStr, $.),
			if
				0 == IsHavePoint ->
					[Pubkey, WorkerID] = [PubkeyWithWorkderIDStr, "None"];
				true ->
					[Pubkey, WorkerID] = string:tokens(PubkeyWithWorkderIDStr, ".")
			end,
			WorkerID64 = base64:encode(WorkerID),
			O = [<<"mining_data">>, list_to_binary(Pubkey), WorkerID64],
			jiffy:encode(O);
		[<<"work">>, Nonce, PubkeyWithWorkderID] ->
			PubkeyWithWorkderIDStr = binary_to_list(PubkeyWithWorkderID),
			IsHavePoint = string:chr(PubkeyWithWorkderIDStr, $.),
			if
				0 == IsHavePoint ->
					[Pubkey, WorkerID] = [PubkeyWithWorkderIDStr, "None"];
				true ->
					[Pubkey, WorkerID] = string:tokens(PubkeyWithWorkderIDStr, ".")
			end,
			WorkerID64 = base64:encode(WorkerID),
			O = [<<"work">>, Nonce, list_to_binary(Pubkey), WorkerID64],
			jiffy:encode(O);
		_ ->
			%io:fwrite(K),
			%io:fwrite("   No luck \n"),
			D
	end.
