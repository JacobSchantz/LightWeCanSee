#ifndef PHYSICS_CALCULATOR_H
#define PHYSICS_CALCULATOR_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class PhysicsCalculator : public RefCounted {
    GDCLASS(PhysicsCalculator, RefCounted);

protected:
    static void _bind_methods();

private:
    double friction_coefficient;
    double air_resistance;

public:
    PhysicsCalculator();
    ~PhysicsCalculator();

    // Main force calculation method
    Vector3 calculate_force(const Vector3 &direction, double force_amount, double mass);
    
    // More detailed calculation with friction and other physics properties
    Vector3 calculate_complex_force(const Vector3 &direction, double force_amount,
                                    double mass, double surface_friction);
    
    // Calculate acceleration based on force and mass (F = ma)
    double calculate_acceleration(double force, double mass);
    
    // Set and get friction coefficient
    void set_friction_coefficient(double friction);
    double get_friction_coefficient() const;
    
    // Set and get air resistance
    void set_air_resistance(double resistance);
    double get_air_resistance() const;
};

}

#endif // PHYSICS_CALCULATOR_H
