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
    
    uint256 public totalSupply;
    
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
        Transfer(0, msg.sender, amount);
        Transfer(tx.origin, this, msg.value);
        return amount;
    }
  
    function sell(uint256 amount) returns (uint revenue, bool success) {
        revenue = amount * price;
        if (balances[tx.origin] >= amount && balances[tx.origin] + amount > balances[tx.origin] && amount > min_order) {
            balances[tx.origin] -= amount;
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
    
    function HumanStandardDragoo(string _dragoName,  string _dragoSymbol, uint256 _transactionFee) {
        name = _dragoName;    
        symbol = _dragoSymbol;
        transactionFee = _transactionFee;
    }
    
    function() {
		throw;
    }
}

contract DragooRegistry {
    
    mapping(uint => address) public dragos;
    mapping(address => uint) public toDrago;
    mapping(address => address[]) public created;
    address public _drago;
	uint public _dragoID;
	uint public nextDragoID;
	bytes public humanStandardByteCode;
    
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
	uint[] _dragoID;
	uint public fee = 0;
	address public dragoDAO = tx.origin;
	address[] newDragos;
	
	modifier when_fee_paid { if (msg.value < fee) return; _ }
	
    event DragoCreated(string _name, address _drago, address _dragowner, uint _dragoID);
    
	function HumanStandardDragooFactory () {
	    
	    }	
	
	function createHumanStandardDragoo(string _name, string _symbol, uint256 _transactionFee) when_fee_paid returns (address _drago, uint _dragoID) {
		HumanStandardDragoo newDrago = (new HumanStandardDragoo(_name, _symbol, _transactionFee));
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
    
    function() {
        throw;
    }
}

contract DragooFactoryInterface is HumanStandardDragooFactory {
    
    HumanStandardDragoo m;

        
    function buyDragoo(address targetDragoo) {
        m = HumanStandardDragoo(targetDragoo);
        m.buy();
    }
    
    function sellDragoo(address targetDragoo, uint256 amount) {
        m = HumanStandardDragoo(targetDragoo);
        m.sell(amount);
    }
    
    function drain() onlyDragowner {
        if (!dragoDAO.send(this.balance))
            throw;
    }
}
