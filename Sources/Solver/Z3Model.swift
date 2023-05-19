import CZ3Api

public extension Z3.Context {
    final class Model: SolverModel {
        private var context: Z3.Context
        private var model: Z3_model

        public init?(context: Z3.Context) {
            guard context.isSatisfiable,
                  let model = Z3_solver_get_model(context.context, context.solver) else {
                return nil
            }
            Z3_model_inc_ref(context.context, model)

            self.context = context
            self.model = model
        }
        deinit {
            Z3_model_dec_ref(context.context, self.model)
        }

        public func satisfies(formula: Z3.Context.Formula) -> Bool? {
            var result: Z3_ast? = nil
            guard Z3_model_eval(context.context, model, formula, false, &result) else {
                return nil
            }
            switch result {
            case context.top:
                return true
            case context.bot:
                return false
            default:
                return nil // partial model
            }
        }
    }
}
