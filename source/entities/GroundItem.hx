package entities;

enum ItemType
{
    ItemStick;
}

class GroundItem extends Entity
{
    public function new()
    {
        super();

        this.type = EntityItem;              
    }
}
