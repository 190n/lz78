// extern struct so padding matches C
pub const FileHeader = extern struct {
    magic: u32,
    protection: u16,
};

pub const magic: u32 = 0xBAADBAAC;
