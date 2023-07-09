// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;
import {Base64} from "base64-sol/base64.sol";
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
   
   receive () external payable onlyOwner(){}
   fallback () external payable onlyOwner(){}

    uint256 public s_tokenID;
    address public immutable implementation;
    uint public salt = 1; 
    address public immutable tokenContract = address(this);
    uint public immutable chainId = block.chainid;
    IERC6551Registry public immutable registry; 

    mapping(uint256=>uint256[]) public As_tokenIDToSalt;
    mapping(uint256=>address payable[]  ) public As_tokenIDTOWalletAddr;
    mapping(address=>mapping(uint256=>uint256)) public s_addrToTokenIDToWalletNonce;
    mapping(address =>uint256[]) public s_addrToTokenID;
    mapping(string=>uint256) public s_NameToSalt;
    mapping(string=>address) public s_NametoWalletAddr;

    constructor(address _implementation,address _registry) ERC721("CentralPayNFT","EUPI") payable{
        s_tokenID=0;
        implementation = _implementation;
        registry = IERC6551Registry(_registry);

    }
    function newNFT(string memory _name,string memory _tokenURI)external{
        if(bytes(_name).length==0 || bytes(_tokenURI).length==0){
            revert Require_Name_TokenURI();
        }
         _safeMint(msg.sender,s_tokenID);
         _setTokenURI(s_tokenID,_tokenURI);
         address user=createAccount(s_tokenID);
         As_tokenIDTOWalletAddr[s_tokenID].push(payable(user));
         s_NametoWalletAddr[_name]=user;
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
         s_NametoWalletAddr[_name]=user;
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

    function depositEThByAdmin(uint256[] memory _value,string[] memory _name,string[] memory /*_useCase*/) external payable onlyOwner{
        if(_value.length!=_name.length){
            revert FalseAddrPair();
        }
         for(uint256 i=0;i<_name.length;i++){
             (bool success,)=(s_NametoWalletAddr[_name[i]]).call{value:_value[i]}("");
          if(!success){
              revert Eth_NotDeposit();
          }
         }
    }

    
}



































    // modifier checkAccount(string memory _name){
    //     if(s_NameToOwnerToWalletaddr[_name][msg.sender]==address(0)){
    //         revert Not_Owner();
    //     }
    //     _;
    // }
    // function depositETH(uint256 _value,string memory _name) external payable onlyOwner(){
    //     address user=s_NameToOwnerToWalletaddr[_name][msg.sender];
    //   (bool success,)=user.call{value:_value}("");
    //      if(!success){
    //          revert Eth_NotDeposit();
    //      }
    // }