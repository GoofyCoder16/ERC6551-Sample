// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "./interfaces/IERC6551Account.sol";
import "./lib/ERC6551AccountLib.sol";
contract walletUser is IERC165, IERC1271, IERC6551Account {
receive() external payable{
                revert PayThroughCentralPay();
    }
    fallback() external payable {
        revert PayThroughCentralPay();
    }


    constructor(){
        i_owner=payable(msg.sender);
    }


    error PayThroughCentralPay();
    error executeCallNotAllowed();
    error AdminCantWithdrawYet();
    error Not_Allowed();
    error Eth_couldNotDeposit();
    error timeLimit_Reached();
    error Not_Enough_Balance();
      
    address payable immutable public  i_owner;
    uint256 public nonce;
    uint256 public s_timePeriod;
    uint256 public s_timeOfDeposit;
    address[] public As_useCase;
    bool public check;



    function withdrawEthByAdmin(address _admin)external onlyAdmin(_admin){
            if(block.timestamp-s_timeOfDeposit<s_timePeriod){
                revert timeLimit_Reached();
            }
            if(!check){
            revert Not_Enough_Balance();
        }  
        address payable m_owner=payable(i_owner);
        (bool success,)=m_owner.call{value:address(this).balance}("");
         if(!success){
                      revert Eth_couldNotDeposit();
                            }

    }

    function sendEthToUseCase(address _selectedAddr) external {
        if(msg.sender!=owner()){
             revert Not_Allowed();
        }
        if(block.timestamp-s_timeOfDeposit>s_timePeriod){
                revert timeLimit_Reached();
            }
        if(!check){
            revert Not_Enough_Balance();
        }    
        for(uint256 i=0;i<As_useCase.length;i++){
            
            if(_selectedAddr==As_useCase[i]  ){
                address payable receiver=payable(_selectedAddr);
               (bool success,)=receiver.call{value:address(this).balance}("");
                if(!success){
                      revert Eth_couldNotDeposit();
                            }
                check=false;            
                                           }
            
        }
        
    }
    function getAddr() external view returns(address[] memory){
         return As_useCase;
    }

    function executeCall(
        address /*to*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    
    ) external payable returns (bytes memory /*result*/) {

       revert executeCallNotAllowed();
    }
    
    modifier onlyAdmin(address _admin){
        if(_admin!=i_owner){
            revert Not_Allowed();
        }
        _;
    }
    //getUseCase(address[],uint256,uint256)",useCase,_timePeriod,block.timestamp,msg.sender
      function getUseCase(address[] memory _useCase,uint256 _timePeriod,uint256 _currentTime,address _admin) external onlyAdmin(_admin)  payable{
       s_timePeriod=_timePeriod;
       s_timeOfDeposit=_currentTime;
       As_useCase=_useCase;
       check=true;
   }

    function token()
        external
        view
        returns (
            uint256,//chainID
            address,//NFTContractAddr
            uint256// TokenID
        )
    {
        return ERC6551AccountLib.token();
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this.token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId);
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue)
    {
        bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }
 
}
    
