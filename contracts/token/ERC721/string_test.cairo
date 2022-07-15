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
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():

    return ()
end

#
# Getters
#

@view
func base64_string{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    }(character_count: felt, data_content : felt) -> (arr_len: felt, arr: felt*):
    

    let (str) = _str_base64_internal(character_count,data_content)
    return (str.arr_len, str.arr)
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
