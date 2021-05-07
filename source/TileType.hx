package;

class TileType
{
    public static final CLIFF_DOWN = 29;
    public static final CLIFF_RIGHT = 35;
    public static final CLIFF_LEFT = 37;
    public static final CLIFF_UP = 43;

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
                return 6;
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
                return 6;
            default:
                return 16;
        }
    }
}
