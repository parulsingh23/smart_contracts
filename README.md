   <meta charset="utf-8" emacsmode="-*- markdown -*-"> <link rel="stylesheet" href="https://casual-effects.com/markdeep/latest/journal.css?">

# smart_contracts
             +--------------------------------+      +---------------------+
             |        modifier                |      |     function        |
             +--------------------------------+      +---------------------+
             |   check_on_init_installment()  |      |  prime_day_Payout() +<---------------------+
             |                                |      |                     |                      |
             +---------------+----------------+      +---------+-----------+                      |
                             |                                 |                                  |
            +----------------v---------------------------------v----------------------+           |
            | queryOracle(string memory url, string memory json, string memory _type) |           |
            +-------------------------------------------------------------------------+           |
            |           pendingQueries[queryId] = QueryType(true,_type);              |           |
            |                                                                         |           |
            +-------------------------------------------------------------------------+           |
                                                                                                  |
         +--------------------------------------------------------------------------------+       |
         |                           provable_query()                                     |       |
         |                                                                                |       |
         +----------------------------------------+---------------------------------------+       |
         |  if (_type == "CurrencyConversion") =v |        if (_type == "DayofMonth") =v  |       |
         |  executes immediately                  |        executes in one day            |       |
         +----------------------------------------+---------------------------------------+       |
         |                      pendingQueries[queryId] = QueryType(true,_type);          |       |
         |                                                                                |       |
         +--------------------------------------+-----------------------------------------+       |
                                                |                                                 |
                                                |                                                 |
                                           XXXXXvXXXXXX                                           |
                                         XXX           X                                          |
                                    XXXXXX             XXXXXXXXXXX                                |
                                   XX  XX               XX       X                                |
                                   X                             X                                |
                                   XX     Provable Oracle       XX                                |
                                    XX                         XX                                 |
                                     XX----------+-------------X                                  |
                                                 |                                                |
+------------------------------------------------v----------------------------------------------| |
|                                   _callback()                                                 | |
+-----------------------------------------------------------------------------------------------+ |
|                    require (pendingQueries[myid].exists == true);                             | |
+-----------------------------------------------------------------------------------------------+ |
|                    delete pendingQueries[myid];                                               | |
+------------------------------------------------+----------------------------------------------+ |
|     if (pendingQueries[myid].exists._type      |    if (pendingQueries[myid].exists._type     | |
|         == "CurrencyConvert")=>                |        == "DayofMonth")                      | |
|                                                |                                              | |
|      funds_change(1/stringToUint(result) * 2); |       split string                           | |
|                                                |                                              | |
|                                                |    if(check_if_prime(stringToUint(_day)      | |
|                                                |         funds_change(.01*this.balance);      | |
|                                                |                                              | |
+------------------------------------------------+---------------------+------------------------+ |
                                                                       |                          |
                                                                       +--------------------------+

