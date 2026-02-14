# bell_circuit.jl
# Bell state circuit with transpilation using Qiskit.jl

using Qiskit
using Qiskit.C  # For low-level C API access

function create_bell_circuit()
    # Create a quantum circuit with 2 qubits and 2 classical bits
    qc = QuantumCircuit(2, 2)
    
    # Apply Hadamard gate to qubit 1
    qc.h(1)
    
    # Apply CNOT gate with control=1, target=2
    qc.cx(1, 2)
    
    # Measure both qubits
    qc.measure(1, 1)
    qc.measure(2, 2)
    
    return qc
end

function create_simple_target(num_qubits::Int)
    """
    Create a simple target with basic gate set:
    - Single-qubit gates: X, SX, RZ
    - Two-qubit gate: ECR (echoed cross-resonance)
    - Measurement
    """
    target = Qiskit.Target(num_qubits)
    
    # Add single-qubit basis gates
    for gate in (QkGate_X, QkGate_SX, QkGate_RZ)
        entry = Qiskit.target_entry_gate(gate)
        for i in 1:num_qubits
            error = 0.001 * i      # Error rate
            duration = 1.0e-7 * i  # Duration in seconds
            qk_target_entry_add_property(entry, [i], duration, error)
        end
        qk_target_add_instruction(target, entry)
    end
    
    # Add two-qubit basis gate (ECR)
    ecr_entry = Qiskit.target_entry_gate(QkGate_ECR)
    for i in 1:num_qubits-1
        inst_error = 0.01 * (num_qubits - i + 1)
        inst_duration = 5.0e-7
        qk_target_entry_add_property(ecr_entry, [i, i + 1], inst_duration, inst_error)
    end
    qk_target_add_instruction(target, ecr_entry)
    
    # Add measurement instruction
    meas_entry = Qiskit.target_entry_measure()
    for i in 1:num_qubits
        error = 0.01
        duration = 1.0e-6
        qk_target_entry_add_property(meas_entry, [i], duration, error)
    end
    qk_target_add_instruction(target, meas_entry)
    
    return target
end

function display_circuit_info(circuit::QuantumCircuit, title::String)
    """Display detailed information about a circuit"""
    println("\n" * "="^60)
    println(title)
    println("="^60)
    println("Number of qubits: ", circuit.num_qubits)
    println("Number of classical bits: ", circuit.num_clbits)
    println("Number of instructions: ", circuit.num_instructions)
    
    println("\nCircuit instructions:")
    for (i, instruction) in enumerate(circuit.data)
        qubit_str = isempty(instruction.qubits) ? "" : " on qubits $(instruction.qubits)"
        clbit_str = isempty(instruction.clbits) ? "" : " → clbits $(instruction.clbits)"
        param_str = isempty(instruction.params) ? "" : " with params $(instruction.params)"
        println("  $i. $(instruction.name)$qubit_str$clbit_str$param_str")
    end
    
    # Count operations
    op_counts = qk_circuit_count_ops(circuit)
    if !isempty(op_counts)
        println("\nOperation counts:")
        for (op_name, count) in op_counts
            println("  $op_name: $count")
        end
    end
end

function main()
    println("Bell Circuit Example with Transpilation")
    println("========================================\n")
    
    # Create the original Bell circuit
    bell_circuit = create_bell_circuit()
    display_circuit_info(bell_circuit, "Original Bell Circuit")
    
    # Create a target for transpilation
    println("\n\nCreating target backend...")
    num_qubits = bell_circuit.num_qubits
    target = create_simple_target(num_qubits)
    println("Target created with $num_qubits qubits")
    
    # Transpile the circuit
    println("\n\nTranspiling circuit...")
    transpile_result = transpile(bell_circuit, target)
    
    # Display transpiled circuit
    display_circuit_info(transpile_result.circuit, "Transpiled Bell Circuit")
    println("$transpile_result")
    return transpile_result
end

# Run the main function
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
