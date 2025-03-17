#include "physics_calculator.h"
#include <godot_cpp/core/class_db.hpp>
#include <cmath>

using namespace godot;

PhysicsCalculator::PhysicsCalculator() : 
    friction_coefficient(0.3),
    air_resistance(0.05) {
}

PhysicsCalculator::~PhysicsCalculator() {
}

void PhysicsCalculator::_bind_methods() {
    // Register methods to be callable from GDScript
    ClassDB::bind_method(D_METHOD("calculate_force", "direction", "force_amount", "mass"), &PhysicsCalculator::calculate_force);
    ClassDB::bind_method(D_METHOD("calculate_complex_force", "direction", "force_amount", "mass", "surface_friction"), &PhysicsCalculator::calculate_complex_force);
    ClassDB::bind_method(D_METHOD("calculate_acceleration", "force", "mass"), &PhysicsCalculator::calculate_acceleration);
    
    // Property bindings
    ClassDB::bind_method(D_METHOD("set_friction_coefficient", "friction"), &PhysicsCalculator::set_friction_coefficient);
    ClassDB::bind_method(D_METHOD("get_friction_coefficient"), &PhysicsCalculator::get_friction_coefficient);
    
    // Register properties using property info directly
    PropertyInfo friction_info;
    friction_info.type = Variant::FLOAT;
    friction_info.name = "friction_coefficient";
    ClassDB::bind_property("PhysicsCalculator", friction_info, "set_friction_coefficient", "get_friction_coefficient");
    
    ClassDB::bind_method(D_METHOD("set_air_resistance", "resistance"), &PhysicsCalculator::set_air_resistance);
    ClassDB::bind_method(D_METHOD("get_air_resistance"), &PhysicsCalculator::get_air_resistance);
    
    // Second property
    PropertyInfo air_info;
    air_info.type = Variant::FLOAT;
    air_info.name = "air_resistance";
    ClassDB::bind_property("PhysicsCalculator", air_info, "set_air_resistance", "get_air_resistance");
}

Vector3 PhysicsCalculator::calculate_force(const Vector3 &direction, double force_amount, double mass) {
    // Basic force calculation (F = ma)
    Vector3 normalized_dir = direction.normalized();
    
    // Scale the force based on the mass (F = ma, so a = F/m)
    // The force_amount is already the force being applied in Newtons
    
    return normalized_dir * force_amount;
}

Vector3 PhysicsCalculator::calculate_complex_force(const Vector3 &direction, double force_amount,
                                                  double mass, double surface_friction) {
    // Normalize the direction vector
    Vector3 normalized_dir = direction.normalized();
    
    // Calculate the effective force after friction
    double effective_friction = surface_friction * friction_coefficient;
    double friction_force = effective_friction * mass * 9.8; // Assuming Earth gravity
    
    // Net force is the applied force minus friction (if positive)
    double net_force = force_amount > friction_force ? force_amount - friction_force : 0.0;
    
    // Apply air resistance proportional to the square of the force
    double drag_factor = 1.0 - (air_resistance * net_force * 0.01);
    if (drag_factor < 0.1) {
        drag_factor = 0.1; // Minimum drag factor
    }
    
    // Final scaled force
    double final_force = net_force * drag_factor;
    
    return normalized_dir * final_force;
}

double PhysicsCalculator::calculate_acceleration(double force, double mass) {
    // Basic acceleration calculation (a = F/m)
    return (mass > 0) ? force / mass : 0.0;
}

void PhysicsCalculator::set_friction_coefficient(double friction) {
    friction_coefficient = friction;
}

double PhysicsCalculator::get_friction_coefficient() const {
    return friction_coefficient;
}

void PhysicsCalculator::set_air_resistance(double resistance) {
    air_resistance = resistance;
}

double PhysicsCalculator::get_air_resistance() const {
    return air_resistance;
}
