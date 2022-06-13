// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract FSTC {
    
    address operator; // the EON operator, who initializes the contract


    mapping(bytes32=>string[])  public operatorRecord;
    mapping(bytes32=>uint) recordSecreteNumber;
    mapping(bytes32=>string[])  public FSList;
    mapping(bytes32=>uint) prices;
    mapping(bytes32=>uint) periods;
    mapping(bytes32=>uint) startingHeight;
    mapping(bytes32=>address[]) FSOwnerHistory; // length is 2, the first one is original owner, the latter one is new owner

    event showFSTrade(bool, address, address[], uint[], string);
    event showTrading(string, address, uint);
    event showCurrentFSOwner(string, address);

    constructor() {
        operator = msg.sender;
    }

    // function registerVON(address _von) public {
    //     require(msg.sender==operator);
    //     vons.push(_von);
    // }

    // function registerNode(uint _n) public {
    //  require(msg.sender==operator);
    //  Nodes.push(_n);
    // }

    // function registerLink(uint _n1, uint _n2) public {
    //  require(msg.sender==operator);
    //     string memory edge = keccak256(abi.encodePacked(_n1, _n2));
    //  Edges.push(edge);
    // }

    function registerByOperator(uint _n1, uint _n2, string memory _fsid, uint _secrect) public {
        require(msg.sender==operator);
        bytes32 edge = keccak256(abi.encodePacked(_n1, _n2));
        operatorRecord[edge].push(_fsid);
        bytes32 fsidhash = keccak256(abi.encodePacked(_fsid));
        recordSecreteNumber[fsidhash] = _secrect;
    }

    function addFS1(string memory _fsId, uint _n1, 
        uint _n2, uint _p, uint _secrect) public {
        bytes32 edge = keccak256(abi.encodePacked(_n1, _n2));
        // bytes32 eh = getHash(edge);
        bytes32 fsidhash = keccak256(abi.encodePacked(_fsId));
        if (recordSecreteNumber[fsidhash]==_secrect) {
            FSList[edge].push(_fsId);
            FSOwnerHistory[fsidhash].push(msg.sender);
            // recordSecreteNumber[fsidhash] = 0;
            prices[fsidhash] = _p;
        }        
    }

    function addFS2(string memory _fsId, uint _n1, 
        uint _n2, uint _p) public {
        bytes32 edge = keccak256(abi.encodePacked(_n1, _n2));
        bytes32 fsidhash = keccak256(abi.encodePacked(_fsId)); 
        // uint lasto = FSOwnerHistory[theid].length;
        if (FSOwnerHistory[fsidhash][0]==msg.sender) {
            FSList[edge].push(_fsId);
            prices[fsidhash] = _p;
        }
    }

    function removeFS(string memory _fsId, uint _n1, 
        uint _n2) public {

        
        bytes32 fsidhash = keccak256(abi.encodePacked(_fsId));
        require(FSOwnerHistory[fsidhash][0]==msg.sender && FSOwnerHistory[fsidhash].length==1);

        bytes32 edge = keccak256(abi.encodePacked(_n1, _n2));
        uint ind;
        uint le = FSList[edge].length;
        for (ind=0; ind<le; ind++) {
            
            if (keccak256(abi.encodePacked(FSList[edge][ind]))==
            keccak256(abi.encodePacked(_fsId))) break;
        }
        for (uint i=ind; i<le-1; i++) {
            FSList[edge][i] = FSList[edge][i+1];
        }

        FSList[edge].pop();
    }


    function checkFS(string memory _fsId) public 
    {
        bytes32 edge = keccak256(abi.encodePacked(_fsId));
        uint lasto = FSOwnerHistory[edge].length-1;
        address owner = FSOwnerHistory[edge][lasto];
        emit showCurrentFSOwner(_fsId, owner);
    }

    function requestAvailableFS(uint[2][10] memory _te, uint[10] memory _p, uint _edgen, uint _perio) public {
        // need to ensure link length is no longer than 10

        require(_perio<=20);

        bytes32[] memory _e = new bytes32[](_edgen);
        for (uint i=0; i<_edgen; i++) {
            _e[i] = keccak256(abi.encodePacked(_te[i][0], _te[i][1]));
        }

        address[] memory vonres = new address[](_edgen) ;
        uint[] memory tradingprice = new uint[](_edgen) ;
        string memory fres = "";

        bool casee = true;
        uint[] memory index = new uint[](_edgen);
        for (uint i=0; i<_edgen; i++) {
            bool hasfs = false;
            if (FSList[_e[i]].length>0) {
                for (uint j=0; j<FSList[_e[i]].length; j++) {
                    string memory fsid = FSList[_e[i]][j];
                    if (_p[i]>prices[keccak256(abi.encodePacked(fsid))]) {
                        hasfs = true;
                        index[i] = j;
                        break;
                    }
                    
                }
            }
            casee = casee && hasfs;
        }
        if (casee) {
            for (uint i=0; i<_edgen; i++) {
                bytes32 e = _e[i];
                uint j = index[i];
                bytes32 fsidhash = keccak256(abi.encodePacked(FSList[e][j]));
                
                vonres[i] = FSOwnerHistory[fsidhash][0];
                tradingprice[i] = prices[fsidhash];
                fres = string(abi.encodePacked(fres, FSList[e][j]));

                for (uint k=j; k<FSList[e].length-1; k++) {
                    FSList[e][k] = FSList[e][k+1]; 
                }
                FSList[e].pop();
                startingHeight[fsidhash] = block.number;
                periods[fsidhash] = _perio;
                FSOwnerHistory[fsidhash].push(msg.sender);     
            }
            emit showFSTrade(true, msg.sender, vonres, tradingprice, fres);
        } else {
            emit showFSTrade(false, msg.sender, vonres, tradingprice, fres);
        }     
    }

    function requestSpecificFS(uint[2][10] memory _te, uint[10] memory _p, string[10] memory _fsid, 
        uint _edgen, uint _perio) public {
        // need to ensure link length is no longer than 10

        require(_perio<=20);

        bytes32[] memory _e = new bytes32[](_edgen);
        bytes32[] memory _fsidHash = new bytes32[](_edgen);
        for (uint i=0; i<_edgen; i++) {
            _e[i] = keccak256(abi.encodePacked(_te[i][0], _te[i][1]));
            _fsidHash[i] = keccak256(abi.encodePacked(_fsid[i]));
        }

        address[] memory vonres = new address[](_edgen) ;
        uint[] memory tradingprice = new uint[](_edgen) ;
        string memory fres = "";

        bool casee = true;
        uint[] memory index = new uint[](_edgen);
        for (uint i=0; i<_edgen; i++) {
            bool hasfs = false;
            if (FSList[_e[i]].length>0) {
                for (uint j=0; j<FSList[_e[i]].length; j++) {
                    bytes32 tmp = keccak256(abi.encodePacked(FSList[_e[i]][j]));
                    if (_p[i]>prices[tmp] && _fsidHash[i]==tmp) {
                        hasfs = true;
                        index[i] = j;
                        break;
                    }
                    
                }
            }
            casee = casee && hasfs;
        }
        if (casee) {
            for (uint i=0; i<_edgen; i++) {
                bytes32 e = _e[i];
                uint j = index[i];
                bytes32 fsidhash = keccak256(abi.encodePacked(FSList[e][j]));
                
                vonres[i] = FSOwnerHistory[fsidhash][0];
                tradingprice[i] = prices[fsidhash];
                fres = string(abi.encodePacked(fres, FSList[e][j]));

                for (uint k=j; k<FSList[e].length-1; k++) {
                    FSList[e][k] = FSList[e][k+1]; 
                }
                FSList[e].pop();
                startingHeight[fsidhash] = block.number;
                periods[fsidhash] = _perio;
                FSOwnerHistory[fsidhash].push(msg.sender);     
            }
            emit showFSTrade(true, msg.sender, vonres, tradingprice, fres);
        } else {
            emit showFSTrade(false, msg.sender, vonres, tradingprice, fres);
        } 
    }

    function reclaimFS(string memory _fsid) public {
        bytes32 fsidhash = keccak256(abi.encodePacked(_fsid));

        require(FSOwnerHistory[fsidhash][0]==msg.sender && FSOwnerHistory[fsidhash].length==2);
        uint h = block.number+startingHeight[fsidhash]+periods[fsidhash];
        if (h>=h) {
            FSOwnerHistory[fsidhash].pop();
            emit showCurrentFSOwner(_fsid, msg.sender);
            // then could call addFS2() to make this FS tradable again
        }
    }

    // function returnFS(string memory _fsid) public {
    //     bytes32 theid = keccak256(abi.encodePacked(_fsid));

    //     uint lasto = FSOwnerHistory[theid].length;
    //     require(FSOwnerHistory[theid][lasto]==msg.sender);
    //     FSOwnerHistory[theid].pop();
    // }
}