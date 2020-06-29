pragma solidity ^0.5.0; //libraries require older version

import "github.com/oraclize/ethereum-api/provableAPI.sol";

//import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./SafeMath.sol";
//import "github.com/Arachnid/solidity-stringutils/strings.sol"; was not working with solidity > 0.5.x
import "github.com/tokencard/contracts/blob/master/contracts/externals/strings.sol";


contract Escrow is usingProvable{
    
    using SafeMath for uint256; //SafeMath library to prevent overflow
    using strings for *;
    
    // Escrow agent
    address agent;
    
    // List of recipients
    address payable[] recipients;    //how do we add in recipients? Do we want a public function that Barbara approves?
                                                //b/c we can't neccessary send a list of strings
    //payable[] public
    // Store money in escrow for each recipient
    mapping(address => uint256) public deposits;
    
    uint256 public creationTime; 
    
    uint256 init_installment_date; 
    
    mapping (bytes32 => QueryType) public pendingQueries;
    
    struct QueryType {
        bool exists;
        string _type; //can be "DayofMonth" or "CurrencyConvert"
    }
    
    
    bool init_installment = false;
    
    enum FundsState {
        AllDelivered,
        NotDelivered
    }
    
    enum QueryState {
        None,
        DayofMonth,
        CurrencyConversion
    }
    
    
    
    
    FundsState public fundsState;
    QueryState public queryState;
    
    modifier onlyAgent() {
        require(msg.sender == agent);
        _;
    }
    
    /*
    modifier checkState() {
        _;
        if (state == NotDelivered) {
            
        }
    }
    */
    
    //modifier to return state to AllDelivered
    
    modifier check_on_init_installment() {
        if (!init_installment) {
            if (now >= init_installment_date) {
                init_installment = true;
                queryOracle("https://api.pro.coinbase.com/products/ETH-USD/ticker", ".price", "CurrencyConversion");
                //send 2 dollars worth of US in ETH
            }
        } 
        _;
    }
    
    function check_if_prime(uint256 n) public returns (bool){ //i don't need to make it payable if it references a pyabable function right?
        if (n <= 1) {
            return false;
        }  
        
        for (int i= 2; i<= n/2 ; i++) {
            if (n % i == 0) {
                return false; //code after return hits is ignored right?
            }
        }
        return true;
    }
    
    function prime_day_Payout() private payable {  //does this work?, esp if function is infintely recursive
        queryOracle("https://api.nasa.gov/planetary/apod?api_key=5JuGZxCwzF3krzqKYh8da0AdPikrvX6jzicKchDu", ".date", "DayofMonth");//add in url
        
        
    }
    
    function queryOracle(string memory url, string memory json, string memory _type) private payable {
        require(provable_getPrice("URL") > this.balance, "Provable query was NOT sent, please add some ETH to cover for the query fee");
        //smart contract should have greater than .01 cent 
        string memory url_query = string(abi.encodePacked("json(", url, ")", json));//can this be in memory?, or must it be in storage....
        //do i need to import abi library?
        
        if (_type == "CurrencyConversion") {

            bytes32 queryId = provable_query("URL", url_query);
        } 
        
        else if (_type == "CurrencyConversion") {
            
            bytes32 queryId = provable_query(24*3600,"URL", url_query);
        }
        
        QueryType memory temp = QueryType(true,_type);//does this work?
        pendingQueries[queryId] = temp;
        
        }
    
    constructor() public {
        agent = msg.sender; 
        fundsState = FundsState.AllDelivered;
        queryState = QueryState.None;
        creationTime = now; 
        init_installment_date = now + 3 * 1 days; 
        //3 = number of days after creation of contract when every reipient gets a 2 dollar initial installment
        
        prime_day_Payout(); //only starts considering one day after contract instantiated
        
    }
    
    function stringToUint(string memory s) public view returns (uint result) { //changed from constant to view
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }
    
    function __callback(bytes32 myid, string memory result) private {
        if (msg.sender != provable_cbAddress()) revert();
        require (pendingQueries[myid].exists == true);
        if (pendingQueries[myid].exists._type == "CurrencyConvert") {
            delete pendingQueries[myid];
             //gives 1ETH = x USD
             funds_change(1/stringToUint(result) * 2);
            
            
            
        } else if (pendingQueries[myid].exists._type == "DayofMonth") {
            //gonna do something for sending that back, so basically check if it's a prime
            string memory _day; 
            result.rsplit("-",_day); //what if day is 08?
            delete pendingQueries[myid];
            if (check_if_prime(stringToUint(_day)) == true) {
                funds_change(.01*this.balance);
            }
            prime_day_Payout(); //never ending
        }
        
        
         // This effectively marks the query id as processed. (don't want callback function of a sent query getting called more than once)
        //call upon function again to check for ex: scheduled_arrivaltime+3*3600 scheduled query in future
    }
    
    // Deposit ether into escrow
    function deposit() public onlyAgent payable { 
        uint256 amount = msg.value;
        for (uint256 i = 0; i < recipients.length; i.add(1)) {
            deposits[recipients[i]] =  deposits[recipients[i]].add(amount.div(recipients.length));
        }
    }
    
    function funds_change(uint256 amount) public onlyAgent payable { 
        
        for (uint256 i = 0; i < recipients.length; i.add(1)) {
            deposits[recipients[i]] =  deposits[recipients[i]].add(amount);
        }
    }
    
    // Transfer ether from escrow to recipient
    function send() public payable {    //I removed onlyAgent b/c of Lazy Execution, I think anybody should be able to trigger this, as long as there is no vulnerability
        for (uint256 i = 0; i < recipients.length; i.add(1)) {
            uint256 payment = deposits[recipients[i]];
            deposits[recipients[i]] = 0;
            recipients[i].transfer(payment);//what if this fails, and amount is too high? 
        }
    }
    
    // Add new wallet address to recipients array
    function addRecipient(address payable recipient) public onlyAgent { //do we want to check multiple recipients haven't been added?
        recipients.push(recipient);
    }
    
    function removeContract() public onlyAgent {    //would this be payable?
        selfdestruct(agent); //sends funds back to Barbara
    }
    
    function updateContract() public onlyAgent {
        
    }
}
