namespace QuiptMappingEngine.Normalization;

public static class NormalizationDictionary
{
    // Normalizes variant terms to a canonical form so both sides can match.
    public static readonly Dictionary<string, string> Map = new(StringComparer.OrdinalIgnoreCase)
    {
        // Display / Screen
        ["screen"] = "display",
        ["display"] = "display",
        ["monitor"] = "display",
        ["scrn"] = "display",
        ["scrnsize"] = "screensize",

        // Color
        ["colour"] = "color",
        ["color"] = "color",
        ["exactcolor"] = "color",
        ["genericcolor"] = "color",

        // Memory / RAM
        ["ram"] = "memory",
        ["memory"] = "memory",
        ["ramsize"] = "memory",
        ["ramtype"] = "memorytype",
        ["rammax"] = "memorymax",

        // Hard disk / Storage
        ["hdd"] = "harddisk",
        ["harddisk"] = "harddisk",
        ["hard"] = "harddisk",
        ["hdtype"] = "harddisk",
        ["hdtypehware"] = "harddisk",
        ["hdsize"] = "storage",
        ["hdspeed"] = "harddiskspeed",

        // Storage / SSD
        ["ssd"] = "storage",
        ["storage"] = "storage",
        ["solid"] = "storage",

        // Brand / Manufacturer
        ["manufacturer"] = "brand",
        ["maker"] = "brand",
        ["brand"] = "brand",
        ["brandname"] = "brand",

        // Model
        ["modelnbr"] = "model",
        ["model"] = "model",

        // Processor / CPU
        ["cpu"] = "processor",
        ["processor"] = "processor",
        ["proc"] = "processor",
        ["cpucore"] = "processorcore",
        ["cpunum"] = "processor",
        ["cpuspeed"] = "processorspeed",
        ["cpuseries"] = "processorseries",
        ["cpucache"] = "processorcache",
        ["numprocessor"] = "processorcount",
        ["cores"] = "core",
        ["core"] = "core",
        ["count"] = "count",

        // GPU / Graphics
        ["gpu"] = "graphics",
        ["graphics"] = "graphics",
        ["gputype"] = "graphics",
        ["gpumodel"] = "graphicsmodel",
        ["gpusize"] = "graphicssize",
        ["video"] = "graphics",

        // Operating System
        ["os"] = "operatingsystem",
        ["operatingsystem"] = "operatingsystem",
        ["desktopos"] = "operatingsystem",

        // Weight
        ["wt"] = "weight",
        ["weight"] = "weight",
        ["itemweight"] = "weight",

        // Dimensions
        ["dim"] = "dimension",
        ["dimensions"] = "dimension",
        ["dimension"] = "dimension",
        ["itemdims"] = "dimension",

        // Description
        ["desc"] = "description",
        ["description"] = "description",

        // Name / Title / Item
        ["title"] = "name",
        ["name"] = "name",
        ["item"] = "item",

        // Wireless / Connectivity / Bluetooth
        ["wifi"] = "wireless",
        ["wireless"] = "wireless",
        ["bluetooth"] = "bluetooth",
        ["bt"] = "bluetooth",
        ["bluetoothver"] = "bluetooth",
        ["bluspd"] = "bluetooth",
        ["connectivity"] = "connectivity",
        ["lancompat"] = "ethernet",

        // Battery
        ["battery"] = "battery",
        ["batt"] = "battery",

        // Image
        ["image"] = "image",
        ["img"] = "image",
        ["photo"] = "image",

        // Price / MSRP
        ["msrp"] = "price",
        ["price"] = "price",

        // SKU / UPC / Identifier
        ["sku"] = "sku",
        ["upc"] = "upc",
        ["ean"] = "ean",

        // Country
        ["country"] = "country",
        ["origin"] = "origin",

        // Warranty
        ["warranty"] = "warranty",

        // Condition
        ["condition"] = "condition",
        ["cond"] = "condition",

        // Lifestyle / Use
        ["pclifestyle"] = "lifestyle",
        ["lifestyle"] = "lifestyle",
        ["uses"] = "uses",

        // USB / Ports
        ["usbprt"] = "usb2ports",
        ["usbpwr"] = "usb3ports",
        ["usbcports"] = "usbcports",
        ["usbprtfrt"] = "usbfrontports",
        ["usb"] = "usb",

        // HDMI / Display ports
        ["hdmi"] = "hdmi",
        ["totaldvi"] = "dvi",
        ["totaldslprt"] = "displayport",
        ["maxdisplsup"] = "maxdisplay",

        // Optical drive
        ["optdr1"] = "opticaldrive",
        ["dvdspd"] = "dvdspeed",

        // Form factor
        ["desktopformfact"] = "formfactor",
        ["formfactor"] = "formfactor",

        // Keyboard / Mouse
        ["keyboardincl"] = "keyboard",
        ["keyboardcon"] = "keyboard",
        ["mouseincl"] = "mouse",
        ["mousecon"] = "mouse",

        // Audio
        ["hdphnjack"] = "headphone",
        ["micphnjack"] = "microphone",
        ["mic"] = "microphone",

        // Energy
        ["energystar"] = "energystar",
        ["epeatlvl"] = "epeat",

        // Release
        ["releasedate"] = "releasedate",
        ["releaseyear"] = "releaseyear",

        // Plug type
        ["plugtype"] = "plugtype",

        // Product generation / line
        ["prodgen"] = "generation",
        ["desktopprodline"] = "productline",

        // Media
        ["mediacardreader"] = "cardreader",

        // Cooling
        ["liquidcool"] = "cooling",

        // PCI slots
        ["totalpcix1"] = "pcislot",
        ["totalpcix8"] = "pcislot",
        ["totalpcix16"] = "pcislot",
        ["availpcix1"] = "pcislot",
        ["availpcix8"] = "pcislot",
        ["availpcix16"] = "pcislot",

        // Expansion bays
        ["totalexpbay"] = "expansionbay",
        ["total35extbay"] = "expansionbay",
        ["total35intbay"] = "expansionbay",

        // Special
        ["specialnote"] = "note",
        ["bundsoft"] = "software",
        ["optanemem"] = "optane",

        // Smartphone-specific
        ["scrnsiz"] = "screensize",
        ["scrnres"] = "resolution",
        ["simtype"] = "sim",
        ["nfc"] = "nfc",
        ["gps"] = "gps",
        ["accelerometer"] = "sensor",
        ["gyroscope"] = "sensor",
    };
}