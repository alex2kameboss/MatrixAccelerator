# set TOP variable
add wave -noupdate -divider xif/issue
add wave -noupdate /$TOP/xif/issue_valid
add wave -noupdate /$TOP/xif/issue_ready
add wave -noupdate /$TOP/xif/issue_req
add wave -noupdate /$TOP/xif/issue_resp

add wave -noupdate -divider xif/register
add wave -noupdate /$TOP/xif/register_valid
add wave -noupdate /$TOP/xif/register_ready
add wave -noupdate /$TOP/xif/register

add wave -noupdate -divider xif/commit
add wave -noupdate /$TOP/xif/commit_valid
add wave -noupdate /$TOP/xif/commit

add wave -noupdate -divider xif/result
add wave -noupdate /$TOP/xif/result_valid
add wave -noupdate /$TOP/xif/result_ready
add wave -noupdate /$TOP/xif/result