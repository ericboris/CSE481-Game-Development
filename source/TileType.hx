package;

class TileType
{
    public static final CLIFF_DOWN = 29;
    public static final CLIFF_RIGHT = 35;
    public static final CLIFF_LEFT = 37;
    public static final CLIFF_UP = 43;

    public static final CLIFF_DOWN_LEFT = 30;
    public static final CLIFF_DOWN_RIGHT = 28;
    public static final CLIFF_UP_LEFT = 44;
    public static final CLIFF_UP_RIGHT = 42;

    public static final WATER = 16;

    public static final WATER_EDGE_RIGHT = 56;
    public static final WATER_EDGE_LEFT = 58;
    public static final WATER_EDGE_UP = 50;
    public static final WATER_EDGE_DOWN = 64;

    // NC stands for "No Collide"
    public static final WATER_EDGE_RIGHT_NC = WATER_EDGE_RIGHT + 42;
    public static final WATER_EDGE_LEFT_NC = WATER_EDGE_LEFT + 42;
    public static final WATER_EDGE_UP_NC = WATER_EDGE_UP + 42;
    public static final WATER_EDGE_DOWN_NC = WATER_EDGE_DOWN + 42;
    public static final WATER_NC = 103;

    public static final TREE_1 = 14;
    public static final TREE_2 = 15;
    public static final TREE_3 = 21;
    public static final TREE_4 = 22;
    
    public static function getWidthOfTile(tile: Int)
    {
        switch (tile)
        {
            case TREE_1, TREE_2, TREE_3, TREE_4:
                // Trees!
                return 8;
            default:
                return 16;
        }
    }

    public static function getHeightOfTile(tile: Int)
    {
        switch (tile)
        {
            case TREE_1, TREE_2, TREE_3, TREE_4:
                // Trees!
                return 8;
            default:
                return 16;
        }
    }
}
