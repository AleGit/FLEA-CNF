import CYices

public extension Yices.Context {
    final class Model: SolverModel {

        private var context: Yices.Context
        private var model: OpaquePointer

        public init?(context: Yices.Context) {
            guard context.isSatisfiable,
                  let model = yices_get_model(context.context, 0)
                    else {
                return nil
            }
            self.context = context
            self.model = model
        }

        deinit {
            yices_free_model(model)
        }

        public func satisfies(formula: Yices.Context.Formula) -> Bool? {
            switch yices_formula_true_in_model(self.model, formula) {
            case 1:
                return true
            case 0:
                return false
            default:
                return nil
            }
        }
    }
}
