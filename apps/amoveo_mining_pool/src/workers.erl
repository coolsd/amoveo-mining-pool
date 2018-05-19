-module(workers).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,
		 handle_info/2,init/1,terminate/2]).

-export([update_worker_share/1, miner_overview/0, miner_detail/1]).

init(ok) -> 
	Account_Worker_Dict = dict:new(),
	% { account, [{workerID, recent_shares_by_worker}]}

	Worker_Sharetime_Dict = dict:new(),    
	% {account, workerID}, [sharetime]

	Worker_Total_Shares_Dict = dict:new(), 
	% {account, workerID}, total_recent_shares_by_worker
	
	Account_Total_Shares_Dict = dict:new(), 
	% account, total_recent_shares_by_account
	Total_Recent_Shares = 0,
	Current_Diff = 0,
	
	{ok, {Account_Worker_Dict, Worker_Sharetime_Dict, 
		  Worker_Total_Shares_Dict, Account_Total_Shares_Dict,
		 Total_Recent_Shares, Current_Diff}}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format(" Workers Module Died!"), ok.
handle_info(_, X) -> {noreply, X}.

test1() -> gen_server:cast(?MODULE, test1).
test2(WorkerID) -> gen_server:call(?MODULE, {test2, WorkerID}).
update_worker_share({Pubkey, WorkerID, Diff}) ->
	gen_server:cast(?MODULE, {update_worker_share, {Pubkey, WorkerID, Diff}}).
miner_overview() -> gen_server:call(?MODULE, miner_overview).
miner_detail(Pubkey) -> gen_server:call(?MODULE, {miner_detail, Pubkey}).

handle_cast(test1, X) -> 
	io:fwrite("test1\n"),
	{noreply, X};

handle_cast({update_worker_share, {Pubkey, WorkerID, Diff}}, X) ->
	io:fwrite("update_worker_share "),
	io:fwrite("Pubkey is  "),
	io:fwrite(packer:pack(Pubkey)),
	io:fwrite("  WorkerID is  "),
	io:fwrite(WorkerID),
	io:fwrite(" \n "),

	Time = element(2, os:timestamp()),
	
	{_Account_Worker_Dict, Worker_Sharetime_Dict, 
	_Worker_Total_Shares_Dict, _Account_Total_Shares_Dict,
	_Total_Recent_Shares, _Diff}  = X,

	% store workerID and time  in Worker_Sharetime_Dict
    BadKey = <<191,197,254,165,198,23,127,233,11,201,164,214,208,94,
	      150,219,111,47,168,132,15,42,181,222,128,130,84,209,42,
	      21,159,133,171,228,66,24,80,231,135,27,10,59,2,19,110,
	      10,55,200,207,191,159,82,152,42,53,36,207,66,201,130,
	      127,26,98,121,228>>,
    if
	Pubkey == BadKey -> 
			New_Worker_Sharetime_Dict = Worker_Sharetime_Dict,
			{noreply, X};
	true ->
		New_Worker_Sharetime_Dict = 
			dict:append({Pubkey, WorkerID}, Time, Worker_Sharetime_Dict)
    end,

	% filter out-dated share record
	Worker_Sharetime_Dict1 = dict:fold(fun(K,V,Acc) ->
		New_V = lists:filter(fun(E) -> Time - E < 30 end, V),
		if
			length(New_V) > 0 ->
				dict:store(K, New_V, Acc);
			true ->
				Acc	
		end
		end, dict:new(), New_Worker_Sharetime_Dict),
	
	io:fwrite("Times is ~p \n", 
			  [dict:fetch({Pubkey, WorkerID}, Worker_Sharetime_Dict1)]),

	% calulate total_recent_shares and store in Account_Total_Shares_Dict
	Total_Recent_Shares = dict:fold(fun(_K, V, Acc) -> Acc + length(V) end, 0, 
									Worker_Sharetime_Dict1 ),

	% calculate Worker_Total_Shares_Dict
	Worker_Total_Shares_Dict1 = dict:map(fun(_Key, V) -> length(V) end, 
										 Worker_Sharetime_Dict1),
	io:fwrite("Recent share of worker ~p ~p is ~p\n", [[Pubkey], [WorkerID],[
					dict:fetch({Pubkey, WorkerID},Worker_Total_Shares_Dict1)]]),	
	% process Account_Worker_Dict
	Account_Worker_Dict1 = dict:fold(fun(K,V,Acc) ->
				{A,W}= K,
				%io:fwrite("A ~p, W ~p, V ~p \n", [A, W, V]),
				dict:append_list(A,[{W,V}], Acc)
			end , dict:new(), Worker_Total_Shares_Dict1),
	io:fwrite("Account_Worker_Dict1: ~p \n", [dict:to_list(Account_Worker_Dict1)]),
	
	% process Account_Total_Shares_Dict
	Account_Total_Shares_Dict1 = dict:fold(fun(K,V,Acc) ->
		{A,W}= K,
		io:fwrite("A ~p, W ~p, V ~p \n", [A, W, V]),
		case dict:find(A, Acc) of
			error -> dict:store(A, V, Acc);
			{ok, B} -> dict:store(A, B + V, Acc)
		end			
		end, dict:new(), Worker_Total_Shares_Dict1),
	io:fwrite("Account_Total_Shares_Dict1 is: ~p \n", [dict:to_list(Account_Total_Shares_Dict1)]),

	{noreply, {Account_Worker_Dict1, Worker_Sharetime_Dict1,
			  Worker_Total_Shares_Dict1, Account_Total_Shares_Dict1,
			  Total_Recent_Shares, Diff}};

handle_cast(_, X) -> {noreply, X}.


handle_call(miner_overview, _From, X) ->
	{Account_Worker_Dict, _Worker_Sharetime_Dict, 
	_Worker_Total_Shares_Dict, _Account_Total_Shares_Dict,
	Total_Recent_Shares, Diff}  = X,
	Active_Accounts = dict:size(Account_Worker_Dict),

	{reply, [Total_Recent_Shares, Active_Accounts, Diff], X};

handle_call({miner_detail, Pubkey}, _From, X) ->
	{Account_Worker_Dict, Worker_Sharetime_Dict, 
	Worker_Total_Shares_Dict, Account_Total_Shares_Dict,
	Total_Recent_Shares, Diff}  = X,
	Recent_Shares = 
		case dict:find(Pubkey, Account_Total_Shares_Dict) of
			error -> 0;
			{ok, AA} -> AA
		end,
	Online_Workers_List = 
		case dict:find(Pubkey, Account_Worker_Dict) of
			error -> [];
			{ok, BB} -> BB
		end,
	Online_Workers_Num = length(Online_Workers_List),


	{reply, [Recent_Shares, Online_Workers_Num, Diff, Online_Workers_List], X};


handle_call({test2, WorkerID}, _From, X) ->
	io:fwrite("test2\n"),
	io:fwrite(WorkerID),
	io:fwrite("\n"),
	{reply, "return value ", X};

handle_call(_, _From, X) -> {reply, X, X}.
