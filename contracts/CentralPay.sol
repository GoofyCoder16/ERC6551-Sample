// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;
import {Base64} from "./lib/base64.sol";
import "./lib/ERC6551AccountLib.sol";
import "./interfaces/IERC6551Registry.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract centralPay is ERC721URIStorage,Ownable{
   error EUPI_Wallet_NotFound();
    error TokenID_DoesNotExist();
    error Eth_NotDeposit();
    error Not_Owner();
    error FalseAddrPair();
    error EUPI_Wallet_Exist();
    error Require_Name_TokenURI();
    error Not_Allowed();
    error invalid_tranxID();

// 1883891 714926  5157285
    event E_depositEThByAdmin(uint256[] indexed _value,string[] _name,address[] indexed useCase,uint256 indexed _timePeriod,uint256,uint256);
    event E_withdrawEThByAdmin(uint256 indexed _id);
   
   receive () external payable onlyOwner(){}
   fallback () external payable onlyOwner(){}

    uint256 public s_tokenID;
    address public immutable implementation;
    uint public salt = 1; 
    address public immutable tokenContract = address(this);
    uint public immutable chainId = block.chainid;
    string public s_tokenURI; // Immutable not working here
    IERC6551Registry public immutable registry; 
    uint256 public s_id;

    mapping(uint256=>uint256[]) public As_tokenIDToSalt;
    mapping(uint256=>address[] ) public As_tokenIDTOWalletAddr;
    mapping(address=>mapping(uint256=>uint256)) public s_addrToTokenIDToWalletNonce;
    mapping(address =>uint256[]) public s_addrToTokenID;
    mapping(string=>uint256) public s_NameToSalt;
    mapping(string=>address payable) public s_NametoWalletAddr;
    mapping(uint256=>address[]) public As_tranxIDtoUseCase;

    constructor(address _implementation,address _registry,string memory _tokenURI) ERC721("CentralPayNFT","EUPI") payable{
        s_tokenID=0;
        implementation = _implementation;
        registry = IERC6551Registry(_registry);
        s_tokenURI=_tokenURI;

    }
    function newNFT(string memory _name)external{
        if(bytes(_name).length==0){
            revert Require_Name_TokenURI();
        }
         _safeMint(msg.sender,s_tokenID);
         _setTokenURI(s_tokenID,s_tokenURI);
         address user=createAccount(s_tokenID);
         As_tokenIDTOWalletAddr[s_tokenID].push(user);
         s_NametoWalletAddr[_name]=payable(user);
         s_NameToSalt[_name]=salt;
         As_tokenIDToSalt[s_tokenID].push(salt);
         s_addrToTokenIDToWalletNonce[msg.sender][s_tokenID]++;
         s_addrToTokenID[msg.sender].push(s_tokenID);
         s_tokenID=s_tokenID+1;
         salt=salt+1;
    }
    function newWalletforNFT(uint256 NFTtokenID,string memory _name) external {
        if(ownerOf(NFTtokenID)!=msg.sender){
          revert TokenID_DoesNotExist();
        }
           if(s_NametoWalletAddr[_name]!=address(0)){
            revert EUPI_Wallet_Exist();
        }
         address user=createAccount(s_tokenID);
         As_tokenIDTOWalletAddr[s_tokenID].push(payable(user));
         s_NametoWalletAddr[_name]=payable(user);
        s_addrToTokenIDToWalletNonce[msg.sender][s_tokenID]++;
         s_NameToSalt[_name]=salt;
        As_tokenIDToSalt[s_tokenID].push(salt);
         salt=salt+1;
       
    }
    function getAccount(string memory _name) public view returns (address) {
        if(s_NametoWalletAddr[_name]==address(0)){
            revert EUPI_Wallet_NotFound();
        }
        return s_NametoWalletAddr[_name];
    }

    function createAccount(uint tokenId) private returns (address) {
        return
            registry.createAccount(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt,
                ""
            );
    }
// Takes input in wei
// in calldata dont use memory keyword + uint ..uint256 is used.
    function depositEThByAdmin(uint256[] memory _value,string[] memory _name,address[] memory useCase,uint256 _timePeriod) external payable onlyOwner{
        if(_value.length!=_name.length){
            revert FalseAddrPair();
        }
         for(uint256 i=0;i<_name.length;i++){
             address payable receiver=(s_NametoWalletAddr[_name[i]]);
             (bool success,)=receiver.call{value:_value[i]}(abi.encodeWithSignature("getUseCase(address[],uint256,uint256,address)",useCase,_timePeriod,block.timestamp,msg.sender));
      if(!success){
          revert Eth_NotDeposit();
      }
      
      As_tranxIDtoUseCase[s_id]=useCase;
      emit E_depositEThByAdmin(_value,_name,useCase,_timePeriod,block.timestamp,s_id);
      s_id+=1;
         }
    }
    function withdraw(uint256 _id) external onlyOwner {
      if(As_tranxIDtoUseCase[_id][0]==address(0)){
          revert invalid_tranxID();
      }
      for(uint256 i=0;i<As_tranxIDtoUseCase[_id].length;i++){
             address payable receiver=payable(As_tranxIDtoUseCase[_id][i]);
             (bool success,)=receiver.call(abi.encodeWithSignature("withdrawEthByAdmin(address)",msg.sender));
      if(!success){
          revert Eth_NotDeposit();
      }
         }
      emit E_withdrawEThByAdmin(_id);
    }
    
}

    