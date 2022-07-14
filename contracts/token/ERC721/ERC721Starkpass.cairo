%lang starknet
%builtins pedersen range_check ecdsa bitwise
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import (
    split_int
)

from starkware.cairo.common.uint256 import (
    Uint256, uint256_add,uint256_le
)

from contracts.token.ERC721.ERC721_base import (
    ERC721_name, ERC721_symbol, ERC721_balanceOf, ERC721_ownerOf, ERC721_getApproved,
    ERC721_isApprovedForAll, ERC721_mint, ERC721_burn, ERC721_initializer, ERC721_approve,
    ERC721_setApprovalForAll, ERC721_transferFrom, ERC721_safeTransferFrom)

from contracts.token.ERC721.ERC721_Metadata_base import (
    ERC721_Metadata_initializer,
    ERC721_Metadata_tokenURI,
    ERC721_Metadata_setBaseTokenURI,
)

from contracts.utils.Ownable_base import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_get_owner,
    Ownable_transfer_ownership
)

from contracts.token.ERC20.IERC20 import IERC20
from contracts.token.ERC721.IERC721 import IERC721

from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.bitwise import bitwise_and

from contracts.caistring.str import (
Str, str_concat,literal_from_number
)
from contracts.utils.base64 import base64_encode

from contracts.openzeppelin.security.safemath import SafeUint256



#
# Storage variables
#


@storage_var
func token_id_sequence() -> (res: Uint256):
end

@storage_var
func eth_address_storage() -> (res: felt):
end

@storage_var
func briq_address_storage() -> (res: felt):
end

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt, symbol : felt, ethaddress : felt, briqaddress: felt):
    ERC721_initializer(name, symbol)
    eth_address_storage.write(ethaddress)

    briq_address_storage.write(briqaddress)

    return ()
end

#
# Getters
#

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
        balance : Uint256):
    let (balance : Uint256) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (owner : felt):
    let (owner : felt) = ERC721_ownerOf(token_id)
    return (owner)
end

@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (approved : felt):
    let (approved : felt) = ERC721_getApproved(token_id)
    return (approved)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, operator : felt) -> (is_approved : felt):
    let (is_approved : felt) = ERC721_isApprovedForAll(owner, operator)
    return (is_approved)
end



@view
func tokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (token_uri_len: felt, token_uri: felt*):
    alloc_locals

    let (l, u) = _create_tokenURI(token_id)
    return (l, u)
end

#
# Custom Externals
#

@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (token_id : Uint256):
    alloc_locals
    
    # get caller address
    let (sender_address) = get_caller_address()

    # get next available token_id
    let (current_token_id_sequence) = token_id_sequence.read()
    let one_as_uint256: Uint256 = Uint256(1,0)
    let (next_token_id_sequence, _) = uint256_add(current_token_id_sequence, one_as_uint256)
    
    # # mint the token to sender
    mint_internal(sender_address,next_token_id_sequence)
    
    # # update token sequence 
    token_id_sequence.write(next_token_id_sequence)
    
    return (next_token_id_sequence)
end

#
# Externals
#

@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, token_id : Uint256):
    ERC721_approve(to, token_id)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, approved : felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, token_id : Uint256):
    ERC721_transferFrom(_from, to, token_id)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, token_id : Uint256, data_len : felt, data : felt*):
    ERC721_safeTransferFrom(_from, to, token_id, data_len, data)
    return ()
end







#
# Internal functions
#

func mint_internal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
_address:felt, _token_id : Uint256):
	ERC721_mint(_address, _token_id)
	return()
end

func _reverse_internal{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    arr_len : felt, arr : felt*
) -> (rev_arr_len : felt, rev_arr : felt*):

    # if our array is empty (i.e. we reached the end of our recursion)
    if arr_len == 0:
        let (rev_arr) = alloc()
        return (0, rev_arr)
    end

    # otherwise, we reverse the rest of our array
    let (rev_rest_len, rev_rest) = _reverse_internal(arr_len-1, arr+1)

    # and then we append the current element (the first of our array)
    # at the end of the reversed array
    assert rev_rest[rev_rest_len] = [arr]

    return (rev_rest_len+1, rev_rest)
end



func _create_tokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (return_arr_len: felt, return_arr: felt*):
    alloc_locals

    let (owner : felt) = ERC721_ownerOf(token_id)

    # user ether balance
    let (ether_token_address) = eth_address_storage.read()
    let (user_token_balance) = IERC20.balanceOf(contract_address = ether_token_address, account=owner)
    let uint_div = Uint256(low=1000000000000000000,high=0)
    let (user_balance_str) = _convert_uint256_to_literal_str(user_token_balance,uint_div)

    # user briq NFT balance
    let (briq_nft_address) = briq_address_storage.read()
    let (briq_balance : Uint256) = IERC721.balanceOf(contract_address = briq_nft_address, owner=owner)




     # prefix
    let (data_prefix_label) = get_label_location(dw_prefix)
    tempvar data_prefix = Str(1, cast(data_prefix_label, felt*))

    # content
    let (data_content_label) = get_label_location(dw_content)
    tempvar data_content = Str(4, cast(data_content_label, felt*))

    # image prefix
    let (data_image_prefix_label) = get_label_location(dw_image_prefix)
    tempvar data_image_prefix = Str(11, cast(data_image_prefix_label, felt*))

    # image style
    let (data_image_style_label) = get_label_location(dw_image_style)
    tempvar data_image_style = Str(9, cast(data_image_style_label, felt*))

    # image content
    let (data_image_content_label) = get_label_location(dw_image_content)
    tempvar data_image_content = Str(9, cast(data_image_content_label, felt*))


    # user balance start
    let (data_user_balance_start_label) = get_label_location(dw_user_balance_start)
    tempvar data_user_balance_start = Str(2, cast(data_user_balance_start_label, felt*))

    # user balance end
    let (data_user_balance_end_label) = get_label_location(dw_user_balance_end)
    tempvar data_user_balance_end = Str(1, cast(data_user_balance_end_label, felt*))


    

    # briq start
    let (data_briq_balance_start_label) = get_label_location(dw_briq_balance_start)
    tempvar data_briq_balance_start = Str(2, cast(data_briq_balance_start_label, felt*))

    # briq end
    let (data_briq_balance_end_label) = get_label_location(dw_briq_balance_end)
    tempvar data_briq_balance_end = Str(1, cast(data_briq_balance_end_label, felt*))


    # briq NFT balance
    let (briq_nft_balance) = _literal_from_number_internal(briq_balance.low)
    


    # image end
    let (data_image_end_label) = get_label_location(dw_image_end)
    tempvar data_image_end = Str(1, cast(data_image_end_label, felt*))
    # end
    let (data_end_label) = get_label_location(dw_end)
    tempvar data_end = Str(1, cast(data_end_label, felt*))

    let (result) = str_concat(data_prefix, data_content)
    let (result) = str_concat(Str(result.arr_len, result.arr), data_image_prefix)
    let (result) = str_concat(Str(result.arr_len, result.arr), data_image_style)
    let (result) = str_concat(Str(result.arr_len, result.arr), data_image_content)

    let (result) = str_concat(Str(result.arr_len, result.arr), data_user_balance_start)
    let (result) = str_concat(Str(result.arr_len, result.arr), user_balance_str)
    let (result) = str_concat(Str(result.arr_len, result.arr), data_user_balance_end)

    let (result) = str_concat(Str(result.arr_len, result.arr), data_briq_balance_start)
    let (result) = str_concat(Str(result.arr_len, result.arr), briq_nft_balance)
    let (result) = str_concat(Str(result.arr_len, result.arr), data_briq_balance_end)

    let (result) = str_concat(Str(result.arr_len, result.arr), data_image_end)
    let (result) = str_concat(Str(result.arr_len, result.arr), data_end)

    return (result.arr_len, result.arr)

    dw_prefix:
    dw 'data:application/json,'
    # dw 'data:application/json;base64,'

    dw_content:
    dw '{"name":"Starkpass",'
    dw '"description":"Starkpass NFT",'
    dw '"image":'
    dw '"data:image/svg+xml,'

    dw_image_prefix:
    dw '<?xml version=\"1.0\"'
    dw ' encoding=\"UTF-8\"?>'
    dw '<svg xmlns='
    dw '\"http://www.w3.org/2000/svg\"'
    dw ' xmlns:xlink='
    dw '\"http://www.w3.org/1999/'
    dw 'xlink\"'
    dw ' version=\"1.1\"'
    dw ' viewBox=\"0 0 400 400\"'
    dw ' preserveAspectRatio='
    dw '\"xMidYMid meet\">'

    dw_image_style:
    dw '<style type=\"text/css\">'
    dw '<![CDATA[text { '
    dw 'font-family: monospace;'
    dw ' font-size: 21px;} '
    dw '.h1 {font-size: 40px;'
    dw ' font-weight: 600;} '
    dw '.h2 {font-size: 13px;'
    dw '}]]>'
    dw '</style>'

    dw_image_content:
    dw '<rect width=\"400\"'
    dw ' height=\"400\"'
    dw ' fill=\"rgb(240, 240, 240)\"'
    dw ' rx=\"15\" />'
    dw '<line x1=\"50\" y1=\"100\"'
    dw ' x2=\"350\" y2=\"100\"'
    dw ' stroke=\"rgb(0, 0, 128)\" />'
    dw '<text class=\"h1\" x=\"50\"'
    dw ' y=\"70\">House Stark</text>'
   
    dw_user_balance_start:
    dw '<text class=\"h2\" x=\"80\"'
    dw ' y=\"120\" >ether &#x1f4b0; '

    dw_user_balance_end:
    dw '</text>'


    dw_briq_balance_start:
    dw '<text class=\"h2\" x=\"80\"'
    dw ' y=\"160\" >briq &#x1F9F1; '

    dw_briq_balance_end:
    dw '</text>'

    dw_image_end:
    dw '</svg>'

    dw_end:
    dw '"}'

end

func _str_base64_internal{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*}(
    character_count: felt, data_content : felt
) -> (return_str : Str):
alloc_locals

    # split the string array and base64 code each character
    let (output_f : felt*) = alloc()
    split_int(data_content, n=31, base=256, bound=256, output=output_f)
    let (rev_len, rev) = _reverse_internal(character_count, output_f)
    let (encoded_arr_len,encoded_arr) = base64_encode(original_str_len=rev_len, original_str=rev)
    tempvar encoded_data_content = Str(encoded_arr_len, cast(encoded_arr, felt*))
    return (encoded_data_content)
end


func _convert_uint256_to_literal_str{
        syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*
    }(uint_value : Uint256, uint_div: Uint256) -> (return_str:Str):

    alloc_locals

     # user balance start
    let (data_decimal_label) = get_label_location(dw_decimal)
    tempvar data_decimal = Str(1, cast(data_decimal_label, felt*))


    let (quotient,rem) = SafeUint256.div_rem(uint_value,uint_div)

    let (str_qt) = _literal_from_number_internal(quotient.low)

    let (str_rem) = _literal_from_number_internal(rem.low)
    let (str_rem_decimal)= _recur_padding_decimal_internal(rem, uint_div, str_rem)

    let (result) = str_concat(Str(str_qt.arr_len, str_qt.arr), data_decimal)
    let (result) = str_concat(Str(result.arr_len, result.arr), str_rem_decimal)

    return (result)

    dw_decimal:
    dw '.'
end

func _literal_from_number_internal{
        syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*
    }(number : felt) -> (str : Str):
alloc_locals

    let (output_f : felt*) = alloc()
    let (outp) = literal_from_number(number)
    assert output_f[0] = outp
    tempvar str_original = Str(1, output_f)
    return (str_original)
end


func _recur_padding_decimal_internal{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*}(
    uint_original : Uint256, uint_ceiling : Uint256, str_original : Str
) -> (return_zero_padding : Str):
alloc_locals

    let uint_mul = Uint256(low=10,high=0) #multiplier *10
    let (uint_res) = SafeUint256.mul(uint_original,uint_mul) # result after multiple by 10

    # if it is over
    let(compare_result) = uint256_le(uint_ceiling,uint_original)
    if compare_result == 1:
        return (str_original)
    end

    # otherwise, we reverse the rest of our array
    let (return_str) = _recur_padding_decimal_internal(uint_res, uint_ceiling, str_original)

    # generate a str represents '0'
    let (output_f : felt*) = alloc()
    let (outp) = literal_from_number(0)
    assert output_f[0] = outp
    tempvar padding_literal_value = Str(1, output_f)
    
    let (concat_result) = str_concat(padding_literal_value, return_str)

    return (concat_result)
end