#!/usr/bin/env bash

get_entry()
{
    local elf_file=$1
    readelf -h "$elf_file" | sed -e '/Entry/!d;s/.*:.*\(0x[0-9a-fA-F]\)/\1/g'
}

gen_cfg_file()
{
cat <<EOF > "$CFG_OUTFILE"
#define __ASSEMBLY__

FIT
BOOT_FROM	sd
LOADER		${SPL_DDR_BIN}	${SPL_ENTRY}
SECOND_LOADER	${UBOOT_BIN}		${UBOOT_ENTRY} 0x60000

EOF
}

gen_1stloader_bin()
{
    SPL_BIN_PAD="$(mktemp --suffix spl_pad.bin)"
    dd if="${SPL_BIN}" of="${SPL_BIN_PAD}"  bs=4 conv=sync
    cat "${SPL_BIN_PAD}" "${DDR_FW_BIN}" > "${SPL_DDR_BIN}"
}

gen_fw_image()
{
    "${HOST_DIR}"/bin/mkimage -n "${CFG_OUTFILE}" -T imx8mimage -e "${SPL_ENTRY}" -d "${UBOOT_BIN}" "${FLASH_BIN}"

}
main()
{
    UBOOT_BIN="${BINARIES_DIR}/u-boot.itb"
    UBOOT_ELF="${BINARIES_DIR}/u-boot"
    SPL_DDR_BIN="${BINARIES_DIR}/u-boot-spl-ddr.bin"
    SPL_BIN="${BINARIES_DIR}/u-boot-spl.bin"
    SPL_ELF="${BINARIES_DIR}/u-boot-spl"
    CFG_OUTFILE="${BINARIES_DIR}/bootimage.cfg"
    FLASH_BIN="${BINARIES_DIR}/imx8-boot-sd.bin"
    UBOOT_ENTRY="$(get_entry "${UBOOT_ELF}")"
    SPL_ENTRY="$(get_entry "${SPL_ELF}")"
    DDR_FW_BIN="${BINARIES_DIR}/lpddr4_pmu_train_fw.bin"

    gen_1stloader_bin
    gen_cfg_file
    gen_fw_image
}

main "$@"
