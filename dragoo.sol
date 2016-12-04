// Copyright 2016 Gabriele Rigo
//! Dragoo contract.
//! By Gabriele Rigo (Rigo Investment), 2016.
//! Released under the Apache Licence 2.

contract Dragoowned {
    address public dragowner;
    
    event NewDragowner(address indexed old, address indexed current);

    function Dragoowned() {
        dragowner = tx.origin;      //double check whether tx.origin, as prev but not workin
    }

    modifier onlyDragowner {
        if (tx.origin != dragowner) return;
        _
    }

    function transferDragownership(address newDragowner) onlyDragowner {
        dragowner = newDragowner;
        NewDragowner(dragowner, newDragowner);
    }
}

contract Dragoo is Dragoowned {
    
    uint256 public totalSupply = 0;
    
    function balanceOf(address _who) constant returns (uint256 balance);
    
    event Transfer(address indexed from, address indexed to, uint256 indexed _amount);
}

contract StandardDragoo is Dragoo {
    
    uint256 public price= 1 finney;
    uint256 public transactionFee = 0; //in basis points (1bps=0.01%)
    uint min_order = 100 finney; // minimum stake to avoid dust clogging things up
    address public feeCollector = tx.origin;
    address public Dragator = msg.sender;
    uint gross_amount;
    uint fee;
    uint fee_dragoo;
    uint fee_dragator;
    uint256 public ratio = 80;
    
    modifier onlyDragator { if (tx.origin != Dragator) return; _ }
    
    function buy() returns (uint amount) {
        if (msg.value < min_order) throw;
        gross_amount = msg.value / price;
        fee = gross_amount * transactionFee / (100 ether);
        fee_dragoo = fee * 80 / 100;
        fee_dragator = fee - fee_dragoo;
        amount = gross_amount - fee;
        balances[tx.origin] += amount;
        balances[feeCollector] += fee_dragoo;
        balances[Dragator] += fee_dragator;
        totalSupply += gross_amount;
        Transfer(0, tx.origin, amount);
        Transfer(tx.origin, this, msg.value);
        return amount;
    }
  
    function sell(uint256 amount) returns (uint revenue, bool success) {
        revenue = amount * price;
        if (balances[tx.origin] >= amount && balances[tx.origin] + amount > balances[tx.origin] && revenue >= min_order) {
            balances[tx.origin] -= amount;
            totalSupply -= amount;
		    if (!tx.origin.send(amount * price)) {
		        throw;
		    } else {  
		       Transfer(tx.origin, 0, amount);
		       Transfer(this, tx.origin, revenue);
		    }
		    return (revenue, true);
		    //return true;
        } else { return (revenue, false); }
    }
    
    function changeRatio(uint256 _ratio) onlyDragator {
        ratio = _ratio;
    }
    
    function setTransactionFee(uint _transactionFee) onlyDragowner {    //exmple, uint public fee = 100 finney;
        transactionFee = _transactionFee * msg.value / (100 ether);   //fee is in basis points (1 bps = 0.01%)
    }
    
    function changeFeeCollector(address _feeCollector) onlyDragowner {
        feeCollector = _feeCollector;
    }
    
    function changeDragator(address _dragator) onlyDragator {
        Dragator = _dragator;
    }

    function balanceOf(address _from) constant returns (uint256 balance) {
        return balances[_from];
    }

    mapping (address => uint256) public balances;
}

contract HumanStandardDragoo is StandardDragoo {
    
    string public name;
    string public symbol;
    string public version = 'H0.1';
    
    function HumanStandardDragoo(string _dragoName,  string _dragoSymbol) {
        name = _dragoName;    
        symbol = _dragoSymbol;
    }
    
    function() {
		buy();
    }
}

contract DragooRegistry {
    
    mapping(uint => address) public dragos;
    mapping(address => uint) public toDrago;
    mapping(address => address[]) public created;
    address public _drago;
//	uint public _dragoID;
	uint public nextDragoID;
    
    function accountOf(uint _dragoID) constant returns (address) {
        return dragos[_dragoID];
    }
    
    function dragoOf(address _drago) constant returns (uint) {
        return toDrago[_drago];
    }
    
    function register(address _drago, uint _dragoID) {
        dragos[_dragoID] = _drago;
        toDrago[_drago] = _dragoID;
    }
}

contract HumanStandardDragooFactory is DragooRegistry, Dragoowned {
	
	string public version = 'DF0.1'; //alt uint public version = 1
//	uint[] _dragoID;
	uint public fee = 0;
	address public dragoDAO = tx.origin;
	address[] public newDragos;
	
	modifier when_fee_paid { if (msg.value < fee) return; _ }
	
    event DragoCreated(string _name, address _drago, address _dragowner, uint _dragoID);
    
	function HumanStandardDragooFactory () {
	    
	    }	
	
	function createHumanStandardDragoo(string _name, string _symbol) when_fee_paid returns (address _drago, uint _dragoID) {
		HumanStandardDragoo newDrago = (new HumanStandardDragoo(_name, _symbol));
		newDragos.push(address(newDrago));
		created[msg.sender].push(address(newDrago));
        newDrago.transferDragownership(tx.origin);
        _dragoID = nextDragoID;     //decided at last to add sequential ID numbers
        ++nextDragoID;              //decided at last to add sequential ID numbers
        register(_drago, _dragoID);
        DragoCreated(_name, address(newDrago), tx.origin, uint(newDrago));
        return (address(newDrago), uint(newDrago));
    }
    
    function setFee(uint _fee) onlyDragowner {    //exmple, uint public fee = 100 finney;
        fee = _fee;
    }
    
    function setBeneficiary(address _dragoDAO) onlyDragowner {
        dragoDAO = _dragoDAO;
    }
    
    function drain() onlyDragowner {
        if (!dragoDAO.send(this.balance))
            throw;
    }
    
    function() {
        throw;
    }
}

contract DragooFactoryInterface is HumanStandardDragooFactory {
    
    address _targetDragoo;
        
    function buyDragoo(address targetDragoo) {
        HumanStandardDragoo m = HumanStandardDragoo(targetDragoo);
        m.buy.value(msg.value)();
    }
    
    function sellDragoo(address targetDragoo, uint256 amount) {
        HumanStandardDragoo m = HumanStandardDragoo(targetDragoo);
        m.sell(amount);
    }
    
    function changeRatio(address targetDragoo, uint256 _ratio) {
        HumanStandardDragoo m = HumanStandardDragoo(targetDragoo);
        m.changeRatio(_ratio);
    }
    
    function setTransactionFee(address targetDragoo, uint _transactionFee) {    //exmple, uint public fee = 100 finney;
        HumanStandardDragoo m = HumanStandardDragoo(targetDragoo);
        m.setTransactionFee(_transactionFee);       //fee is in basis points (1 bps = 0.01%)
    }
    
    function changeFeeCollector(address targetDragoo, address _feeCollector) {
        HumanStandardDragoo m = HumanStandardDragoo(targetDragoo);
        m.changeFeeCollector(_feeCollector);
    }
    
    function changeDragator(address targetDragoo, address _dragator) {
        HumanStandardDragoo m = HumanStandardDragoo(targetDragoo);
        m.changeDragator(_dragator);
    }
}
